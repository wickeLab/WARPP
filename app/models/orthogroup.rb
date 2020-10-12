class Orthogroup < ApplicationRecord
  # MIXINS
  include TreeFormatter

  # CONSTANTS

  # ATTRIBUTES
  has_one_attached :sequence_file
  has_one_attached :tree_file
  has_one_attached :json_tree

  # MISCELLANEOUS

  # ASSOCIATIONS
  has_many :orthogroup_taxons
  has_many :taxa, through: :orthogroup_taxons, source: :taxon

  has_one :tree, dependent: :destroy

  # VALIDATIONS
  validates :tree, presence: true
  validates :identifier, presence: true, uniqueness: true

  # SCOPES

  # CALLBACKS
  before_create :setup_orthogroup_taxons, :attach_files, :build_json_tree
  before_destroy :destroy_dependencies

  # INSTANCE METHODS
  def retrieve_members_per_taxon
    orthogroup_taxons.map(&:fetch_members_as_json).sort_by { |x| x[:taxon] }.to_json
  end

  def build_json_tree
    tree_file = Rails.root.join('data', 'orthogroups', 'orthogroup_trees', "#{identifier}_tree_labelled.txt")
    json_file = Rails.root.join('data', 'orthogroups', 'orthogroup_trees', "#{identifier}_tree.json")
    File.open(json_file, 'w') do |f|
      f.puts newick_to_json(tree_file)
    end
    json_tree.attach(io: File.open(json_file), filename: "#{identifier}_tree.json", content_type: 'text/plain')
  end

  def set_function_realm
    a_thaliana = Taxon.where(scientific_name: 'Arabidopsis thaliana').first

    function_array = if taxa.include?(a_thaliana)
                       orthogroup_taxons.where(taxon: a_thaliana).first.entries.map do |entry|
                         entry.scan(/(?<=\d\s)[a-z\s]+[a-z]/i)[0]
                       end.uniq - [nil]
                     end

    function_array = function_array&.length&.positive? ? function_array : ['unknown']

    update(function_realm: function_array)
  end

  def map_taxa_presence(taxa)
    taxa.map do |taxon|
      [taxon, check_taxon_presence(taxon)]
    end
  end

  def check_taxon_presence(scientific_name)
    taxa.exists?((Taxon.find_by scientific_name: scientific_name).id)
  end

  # CLASS METHODS
  def self.all_taxa
    all_taxa = Taxon.where(id: OrthogroupTaxon.pluck(:taxon_id).uniq).pluck(:scientific_name)
    (all_taxa - ['Arabidopsis thaliana']).sort.unshift('Arabidopsis thaliana')
  end

  def self.overwrite_orthogroups
    # TODO: redo
    CSV.open(Rails.root.join('data', 'orthogroups', 'orthogroups.tsv'), headers: true, col_sep: "\t").each do |row|
      orthogroup = nil

      row.each do |header, value|
        if header == 'Orthogroup'
          orthogroup = Orthogroup.find_by identifier: value

          if orthogroup
            break
            puts 'Destroying current orthogroup data...'
            old_tree = orthogroup.tree
            orthogroup.orthogroup_taxons.destroy_all
            orthogroup.sequence_file.purge
            orthogroup.tree_file.purge
          else
            orthogroup = Orthogroup.new(identifier: value)
          end

          #puts "Generating labelled tree: " +  value
          #self.name_internal_nodes(value)
          puts 'Loading tree: ' + value
          #tree_file = Rails.root.join('data', 'orthogroups', "orthogroup_trees", "#{value}_tree_labelled.txt")
          tree_file = Rails.root.join('data', 'orthogroups', 'orthogroup_trees', "#{value}_tree.txt")
          sequence_file = Rails.root.join('data', 'orthogroups', 'orthogroup_sequences', "#{value}.fa")
          orthogroup.tree = Tree.create_trees(tree_file: tree_file, types: %w(ortho))

          old_tree&.destroy

          orthogroup.save
          if File.file?(sequence_file)
            orthogroup.sequence_file.attach(io: File.open(sequence_file), filename: "#{value}.fa", content_type: 'text/plain')
          end
          orthogroup.tree_file.attach(io: File.open(tree_file), filename: "#{value}_tree.txt", content_type: 'text/plain')
        elsif value
          species_name = header.scan(/[A-Z][a-z]+_[a-z]+/)[0].gsub('_', ' ')
          species_entry = Taxon.find_by scientific_name: species_name

          puts 'Generating OrthogroupTaxon for: ' + orthogroup.identifier + species_name

          species_entry ||= Taxon.create(scientific_name: species_name)

          functions = value.split(', ')

          OrthogroupTaxon.create(orthogroup: orthogroup, taxon: species_entry, functions: functions, identifier: header)
        end
      end
    end
  end

  # PRIVATE METHODS
  private

  def attach_files
    tree_file = Rails.root.join('data', 'orthogroups', 'orthogroup_trees', "#{value}_tree.txt")
    tree_file.attach(io: File.open(tree_file), filename: "#{identifier}_tree.nwk", content_type: 'text/plain')

    sequence_file = Rails.root.join('data', 'orthogroups', 'orthogroup_sequences', "#{identifier}.fa")

    return unless File.file?(sequence_file)

    sequence_file.attach(io: File.open(sequence_file), filename: "#{identifier}.fa", content_type: 'text/plain')
  end

  def destroy_dependencies
    tree&.destroy
    Tree.orpahan_trees.destroy_all
    Node.orpahan_nodes.each(&:destroy_all)
  end
end
