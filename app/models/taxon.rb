# frozen_string_literal: true

class Taxon < ApplicationRecord
  # MIXINS
  extend Ascii

  # CONSTANTS
  FAMILY_ORDER = %w[ Orobanchaceae Convolvulaceae Lennoaceae Mitrastemonaceae
                     Apodanthaceae Cytinaceae Rafflesiaceae Krameriaceae Cynomoriaceae Erythropalaceae Ximeniaceae Olacaceae
                     Misodendraceae Schoepfiaceae Loranthaceae Opiliaceae Comandraceae Thesiaceae Cervantesiaceae Nanodeaceae
                     Santalaceae Amphorogynaceae Viscaceae Balanophoraceae Mystropetalaceae Hydnoraceae Lauraceae ].freeze
  AVAILABLE_GENOME_BROWSERS = ['Arabidopsis thaliana', 'Cuscuta campestris', 'Cuscuta australis', 'Striga asiatica'].freeze

  # ATTRIBUTES
  attr_accessor :taxonomic_information

  # MISCELLANEOUS
  has_ancestry cache_depth: true

  # ASSOCIATIONS
  has_many :parasitized_species, foreign_key: :parasite_id, class_name: 'ParasiticRelationship'
  has_many :hosts, through: :parasitized_species

  has_many :hosted_species, foreign_key: :host_id, class_name: 'ParasiticRelationship'
  has_many :parasites, through: :hosted_species

  has_many :publication_taxons
  has_many :publications, through: :publication_taxons, source: :publication

  has_many :plant_images, dependent: :destroy
  has_one :gen_bank, dependent: :destroy

  has_many :orthogroup_taxons
  has_many :orthogroups, through: :orthogroup_taxons, source: :orthogroup

  has_many :lifetraits, dependent: :destroy
  has_many :submissions, dependent: :destroy


  # VALIDATIONS
  validates :scientific_name, presence: true, uniqueness: true

  # SCOPES
  # navbar search scope
  include PgSearch::Model
  pg_search_scope :kinda_spelled_like,
                  against: :scientific_name,
                  using: :trigram,
                  ranked_by: ':trigram'

  scope :species, lambda {
    where('scientific_name ~* ?', "[A-Z][a-z]+\s[a-z]+")
  }

  scope :parasites, lambda {
    species.where.not(ancestry: nil)
  }

  scope :hosts, lambda {
    where(id: ParasiticRelationship.pluck(:host_id).uniq)
  }

  scope :species_of_family, lambda { |family|
    where('ancestry LIKE ?', "#{(Taxon.find_by scientific_name: family).id}/%").species
  }

  scope :root, lambda { |scientific_name|
    where('scientific_name LIKE ?', scientific_name).first.root
  }

  scope :max_depth, lambda { |family_name|
    where('scientific_name LIKE ?', family_name).first.subtree.pluck(:ancestry_depth).max
  }

  scope :family_names, lambda {
    families.pluck(:scientific_name)
  }

  scope :families, lambda {
    where('scientific_name ~* ?', '^[A-Za-z]+eae$').order(:scientific_name)
  }

  # CALLBACKS
  before_create :create_ancestry,
                if: Proc.new { |taxon| taxon.scientific_name =~ /[A-Z][a-z]+\s[a-z]+/ && !taxon.has_parent? && !ancestry }

  after_create :fetch_genbank,
               if: Proc.new { scientific_name =~ /[A-Z][a-z]+\s[a-z]+/ && ancestry? }

  after_update :delete_publications, :fetch_publications,
               if: Proc.new { scientific_name =~ /[A-Z][a-z]+\s[a-z]+/ && ancestry? && previous_changes.include?('scientific_name') }

  before_save :calculate_information_score, :calculate_reliability_score

  # INSTANCE METHODS
  def family
    root.scientific_name
  end

  def family?
    Taxon.families.exists?(id: id)
  end

  def genus
    parent.scientific_name
  end

  def genus?
    # TODO
  end

  def lifestyle
    lifetraits.where(type: 'Lifestyle').pluck(:information).first
  end

  def lifespan
    lifetraits.where(type: 'Lifespan').pluck(:information).first
  end

  def habit
    lifetraits.where(type: 'Habit').pluck(:information).first
  end

  def chromosome_number
    lifetraits.where(type: 'ChromosomeNumber').pluck(:information)
  end

  def genome_size
    lifetraits.where(type: 'GenomeSize').pluck(:information)
  end

  def information_status
    case information_score
    when 0.0
      'unknown'
    when (0.0..0.5)
      'meager'
    when (0.5..0.75)
      'decent'
    else
      'good'
    end
  end

  def collect_references
    info_entries = lifetraits.includes(:publications)
    parasites_rel_entry = hosted_species.includes(:publications, :parasite)
    parasites_rel_entry = parasites_rel_entry.joins(:parasite).merge(Taxon.order(scientific_name: :asc))

    hosts_rel_entry = parasitized_species.includes(:publications, :host)
    hosts_rel_entry = hosts_rel_entry.joins(:host).merge(Taxon.order(scientific_name: :asc))

    sorted_references = []
    info_w_references = {}
    parasites_w_references = {}
    hosts_w_references = {}

    info_entries.each do |info_entry|
      sorted_references |= info_entry.publications.to_a
      info_w_references[info_entry.type] ||= []
      info_w_references[info_entry.type] << [info_entry.information, info_entry.publications.map{ |ref| sorted_references.index(ref) }]
    end

    info_w_references['ChromosomeNumber']&.sort_by! { |k, _v| k.to_i }
    info_w_references['GenomeSize']&.sort_by! { |k, _v| k.to_i }

    parasites_rel_entry.each do |parasite_entry|
      sorted_references |= parasite_entry.publications.to_a
      parasites_w_references[parasite_entry.parasite.scientific_name] = parasite_entry.publications.map{ |ref| sorted_references.index(ref) }
    end

    hosts_rel_entry.each do |host_entry|
      sorted_references |= host_entry.publications.to_a
      hosts_w_references[host_entry.host.scientific_name] = host_entry.publications.map{ |ref| sorted_references.index(ref) }
    end

    i = 1
    indexed_references = {}
    sorted_references.each do |ref|
      parsed_ref = ref.authors_to_string
      if ref.doi
        indexed_references[i] = ["#{parsed_ref} #{ref.year}", "https://doi.org/#{ref.doi}"]
      elsif ref.url
        indexed_references[i] = ["#{parsed_ref} #{ref.year}", ref.url]
      else
        indexed_references[i] = ["#{parsed_ref} #{ref.year}"]
      end
      i += 1
    end

    return indexed_references, info_w_references, parasites_w_references, hosts_w_references
  end

  def collect_trait_information
    {
      'lifespan' => lifespan,
      'lifestyle' => lifestyle
    }
  end

  def collect_photo_information
    counter = 0
    attribution_collector = {}
    plant_images.each do |image_entry|
      attribution_collector[counter] = image_entry.attribution_to_hash
      counter += 1
    end

    attribution_collector
  end

  def fetch_genbank
    GenBank.create(taxon: self)
  end

  def fetch_publications
    puts "Fetching recent publications for: #{scientific_name}"
    scientific_name_ascii = Publication.encode(scientific_name)
    Retryable.retryable(tries: 3, on: [OpenURI::HTTPError, Timeout::Error, Errno::ENETUNREACH, Net::OpenTimeout]) do
      # ids_json = HTTParty.get("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=#{scientific_name_ascii}&retmode=json&retmax=10&api_key=#{Rails.application.credentials[:nih][:api_key]}")
      ids_json = HTTParty.get("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=#{scientific_name_ascii}&retmode=json&retmax=10")
      ids_json = ids_json.parsed_response

      begin
        Publication.fetch_ncbi_publications(ids_json, self)
      rescue => e
        puts "Rescued: #{e.inspect}"
        puts 'Further information: ' + scientific_name
      end
    end

    puts 'Publications after updating: ' + publications.length.to_s
  end

  def retrieve_inaturalist_taxon_id
    scientific_name_ascii = Taxon.encode(scientific_name)
    api_url = "https://api.inaturalist.org/v1/taxa?q=#{scientific_name_ascii}"

    Retryable.retryable(tries: 3, on: [OpenURI::HTTPError, Timeout::Error, Errno::ENETUNREACH]) do
      response = HTTParty.get(api_url).parsed_response
      response['results']&.each do |result|
        return result['id'] if result['name'] == scientific_name
      end
    end

    nil
  end

  def fetch_photos_from_inaturalist
    scientific_name = self.scientific_name
    puts 'Fetching photos for ' + scientific_name
    taxon_id = retrieve_inaturalist_taxon_id
    current_photo_count = plant_images.length

    if taxon_id
      PlantImage::ALLOWED_LICENSES.each do |license|
        Retryable.retryable(tries: 3, on: [OpenURI::HTTPError, Timeout::Error]) do
          url = "https://www.inaturalist.org/observations.json?taxon_id=#{taxon_id}&photo_license=#{license}&has[]=photos&quality_grade=research&order_by=observed_on&order=desc"
          response = HTTParty.get(url)
          response.each do |entry|
            photos = entry['photos']
            if photos && photos.length > 0
              photo = photos[0]
              current_photo_count += 1

              if current_photo_count == 11
                return
              end

              photo_url = photo['large_url']
              plant_image = PlantImage.new(taxon: self)

              plant_image.license = license
              if photo['native_realname'] && !photo['native_realname'].empty?
                plant_image.attribution = photo['native_realname']
              else photo['native_username']
                   plant_image.attribution = photo['native_username']
              end
              plant_image.location_data = entry['place_guess']
              plant_image.observed_on = entry['observed_on']

              plant_image.publisher = 'iNaturalist'
              plant_image.reference_url = photo['native_page_url']

              plant_image.save

              file = open(photo_url)
              plant_image.image.attach(io: file, filename: "#{scientific_name.gsub(' ', '_')}_#{current_photo_count}.jpg", content_type: 'image/jpg')
            end
          end
        end
      end
    end
  end

  def retrieve_GBIF_children(taxon_id = nil)
    parent_name = scientific_name
    taxon_id ||= Taxon.retrieve_GBIF_taxon_id(parent_name)
    gbif_children = nil
    Retryable.retryable(tries: 3, on: [OpenURI::HTTPError, Timeout::Error, Errno::ENETUNREACH]) do
      gbif_children = HTTParty.get("https://api.gbif.org/v1/species/#{taxon_id}/children?limit=1000").parsed_response['results']
    end

    gbif_children.each do |entry|
      if entry['taxonomicStatus'] == 'ACCEPTED'
        if entry['family'] == parent_name
          authorship = entry['authorship']
          taxon_name = entry['genus']
          taxon = Taxon.create(scientific_name: taxon_name, parent: self, authorship: authorship)
          taxon_id = entry['taxonID'].scan(/(?<=gbif:)\d+/)[0]
          taxon.retrieve_GBIF_children(taxon_id)
        elsif entry['genus'] == parent_name
          authorship = entry['authorship']
          taxon_name = entry['species']
          taxon = Taxon.create(scientific_name: taxon_name, parent: self, authorship: authorship)
        end
      end
    end
  end

  def calculate_reliability_score
    self.reliability_score = 0.0
  end

  def calculate_information_score
    lifetrait_values = [lifespan, lifestyle, habit, genome_size, chromosome_number]
    self.information_score = 1 - (lifetrait_values.count(nil) / Lifetrait::LIFETRAIT_COUNT)
  end


  # CLASS METHODS
  def self.destroy_family_data(family)
    destroy(root(family).id)
  end

  def self.fetch_filtered_tree_JSON(family, filter_choices = nil)
    if !filter_choices
      if family != 'Convolvulaceae'
        tree_of_interest = root(family).subtree
      else
        cuscuta_entry = Taxon.find_by scientific_name: 'Cuscuta'
        tree_of_interest = cuscuta_entry.subtree.or(Taxon.where(scientific_name: 'Convolvulaceae'))
      end
    else
      tree_of_interest = Taxon.fetch_filtered_subtree(family, filter_choices)
    end

    a = tree_of_interest.arrange_serializable do |parent, children|
      {
        name: parent.scientific_name,
        information_score: parent.information_score,
        children: children
      }
    end

    return JSON.pretty_generate(a[0]), collect_lifetrait_scores(tree_of_interest)
  end

  def self.fetch_filtered_subtree(family, filter_choices)
    query_type = filter_choices['query_type']
    root_entry = root(family)

    if family == 'Convovulaceae'
      cuscuta_entry = Taxon.find_by scientific_name: 'Cuscuta'
      tree_of_interest = cuscuta_entry.subtree.or(root_entry)
      species_of_interest = tree_of_interest.species
      base_entries = root_entry
    else
      tree_of_interest = root_entry.subtree
      species_of_interest = tree_of_interest.species
      base_entries = tree_of_interest.where('ancestry_depth < ?', 3)
    end

    if filter_choices.values == ['independently'] # if parameters are empty
      return species_of_interest.or(base_entries)
    end

    # as long as parameters are not empty
    lifespan_choices = filter_choices['lifespan'].values
    lifestyle_choices = filter_choices['lifestyle'].values
    information_choices = filter_choices['information_score']

    if query_type == 'independently'
      filtered_tree = Taxon.none
      unless lifespan_choices.empty?
        filtered_tree = filtered_tree.or(subset_subtree(species_of_interest, lifespan_choices, 'Lifespan', ))
      end
      unless lifestyle_choices.empty?
        filtered_tree = filtered_tree.or(subset_subtree(species_of_interest, lifestyle_choices, 'Lifestyle', ))
      end
    else # combined
      filtered_tree = Taxon.all
      unless lifespan_choices.empty?
        filtered_tree = filtered_tree.merge(subset_subtree(species_of_interest, lifespan_choices, 'Lifespan'))
      end
      unless lifestyle_choices.empty?
        filtered_tree = filtered_tree.merge(subset_subtree(species_of_interest, lifestyle_choices, 'Lifestyle'))
      end
    end
    unless information_choices == 'unknown'
      filtered_tree = filtered_tree.merge(subset_subtree(species_of_interest, information_choices))
    end

    p filtered_tree
    filtered_tree.or(base_entries)
  end

  def self.subset_subtree(species_of_interest, category_filter_choices, category = nil)
    case category
    when 'information_score'
      tresholds = { 'good' => 0.75, 'decent' => 0.5, 'meager' => 0.25 }
      treshold = tresholds[category_filter_choices[0]]
      filtered_subtree = species_of_interest.where('information_score > ?', treshold)
    else
      filtered_subtree = species_of_interest.includes(:lifetraits).where('lifetraits.information = ?', category_filter_choices[0]).references(:lifetraits)
      if category_filter_choices.length > 1
        category_filter_choices[1...category_filter_choices.length].each do |filter_choice|
          filter_addition = species_of_interest.includes(:lifetraits).where('lifetraits.information = ?', category_filter_choices[0]).references(:lifetraits)
          filtered_subtree = filtered_subtree.or(filter_addition)
        end
      end

      filtered_subtree = species_of_interest.where(id: filtered_subtree.pluck(:id))
    end

    filtered_subtree
  end

  def self.collect_lifetrait_scores(filtered_oro_tree)
    species_depth = filtered_oro_tree.pluck(:ancestry_depth).max
    taxa = filtered_oro_tree.at_depth(species_depth)

    pie_chart_info = {}

    taxa.each do |taxon|
      parent_name = taxon.parent.scientific_name

      pie_chart_info[parent_name] ||= {
        information_score: {
          unknown: 0,
          meager: 0,
          decent: 0,
          good: 0
        },
        lifespan: {
          unknown: 0,
          annual: 0,
          biennial: 0,
          perennial: 0
        },
        lifestyle: {
          unknown: 0,
          autotroph: 0,
          facultative: 0,
          obligate: 0,
          holoparasitic: 0
        },
        habit: {
          unknown: 0,
          herbaceous: 0,
          tree: 0
        }
      }

      case taxon.information_score
      when 0.0
        pie_chart_info[parent_name][:information_score][:unknown] += 1
      when (0.0..0.5)
        pie_chart_info[parent_name][:information_score][:meager] += 1
      when (0.5..0.75)
        pie_chart_info[parent_name][:information_score][:decent] += 1
      else
        pie_chart_info[parent_name][:information_score][:good] += 1
      end

      case taxon.lifespan
      when 'annual'
        pie_chart_info[parent_name][:lifespan][:annual] += 1
      when 'biennial'
        pie_chart_info[parent_name][:lifespan][:biennial] += 1
      when 'perennial'
        pie_chart_info[parent_name][:lifespan][:perennial] += 1
      else
        pie_chart_info[parent_name][:lifespan][:unknown] += 1
      end

      case taxon.lifestyle
      when 'autotroph'
        pie_chart_info[parent_name][:lifestyle][:autotroph] += 1
      when 'facultative'
        pie_chart_info[parent_name][:lifestyle][:facultative] += 1
      when 'obligate'
        pie_chart_info[parent_name][:lifestyle][:obligate] += 1
      when 'holoparasitic'
        pie_chart_info[parent_name][:lifestyle][:holoparasitic] += 1
      else
        pie_chart_info[parent_name][:lifestyle][:unknown] += 1
      end

      case taxon.habit
      when 'herbaceous'
        pie_chart_info[parent_name][:habit][:herbaceous] += 1
      when 'tree'
        pie_chart_info[parent_name][:habit][:tree] += 1
      else
        pie_chart_info[parent_name][:habit][:unknown] += 1
      end
    end

    pie_chart_info.to_json
  end

  def self.retrieve_GBIF_taxon_id(scientific_name)
    scientific_name_ascii = Taxon.encode(scientific_name)
    api_url = "http://api.gbif.org/v1/species/search?q=#{scientific_name_ascii}"

    response = nil
    while response == nil
      response = HTTParty.get(api_url)
    end

    response.parsed_response['results'].each do |result|
      if result['nubKey']
        return taxon_key = result['nubKey']
      end
    end
  end

  def self.collect_genera(families = 'all')
    family_genera = {}
    if families == 'all'
      self.families.each do |family|
        family_genera[family.scientific_name] = family.descendants.at_depth(2).pluck(:scientific_name).sort
      end
    end

    family_genera.to_json
  end

  def self.add_family_via_GBIF(family_name)
    family = Taxon.create(scientific_name: family_name)
    family.retrieve_GBIF_children
    Taxon.rebuild_depth_cache!
  end

  def self.add_genome_sizes
    Dir["#{Rails.root.join('data', 'genome_sizes')}/*"].each do |input_csv|
      CSV.open(input_csv, headers: true, col_sep: "\t").each do |row|
        scientific_name = row['species'].gsub('_', ' ').gsub(/\s[0-9]+(?=$)/, '')
        puts 'Processing... ' + species
        species_entry = Taxon.where(scientific_name: scientific_name).first

        next unless species_entry

        genome_size = row['GenomeSize1CMbp'].to_i
        GenomeSize.where(taxon: species_entry, information: genome_size).first_or_create!
      end
    end
  end


  # private methods
  private

  def create_ancestry
    species_name = scientific_name

    puts 'Creating ancestry for: ' + species_name

    unless species_name.include?('unclassified')
      genus_name = species_name.split(' ')[0]
      genus_entry = Taxon.find_by scientific_name: genus_name

      if genus_entry
        self.parent = genus_entry
      else
        if taxonomic_information == nil
          scientific_name_ascii = Taxon.encode(species_name)
          Retryable.retryable(tries: 3, on: [OpenURI::HTTPError, Timeout::Error, Errno::ENETUNREACH]) do
            id = HTTParty.get("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=taxonomy&term=#{scientific_name_ascii}&retmode=json&retmax=1&api_key=#{Rails.application.credentials[:nih][:api_key]}")
            id = id['esearchresult']['idlist'][0]

            Retryable.retryable(tries: 3, on: [OpenURI::HTTPError, Timeout::Error, Errno::ENETUNREACH]) do
              self.taxonomic_information = Nokogiri::XML(open("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=taxonomy&id=#{id}&retmode=xml&api_key=#{Rails.application.credentials[:nih][:api_key]}"))
            end
          end
        end

        begin
          lineage = taxonomic_information.at_xpath('//Lineage').content
          if lineage.include?('Orobanchaceae')
            genus_name = lineage.split('; ')[-1]
            genus_entry = Taxon.find_by scientific_name: genus_name
            self.parent = genus_entry
          end
        rescue NoMethodError => e
          puts "Rescued: #{e.inspect}"
          puts 'Further information: '
          p lineage
          p species_name
        end
      end
    end
  end
end
