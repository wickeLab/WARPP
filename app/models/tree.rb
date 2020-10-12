class Tree < ApplicationRecord
  # MISCELLANEOUS
  enum basis: %i[nuc pt ortho]

  # CALLBACKS
  before_destroy :destroy_nodes

  # VALIDATIONS
  validates :basis, presence: true,
            if: Proc.new { orthogroup.nil?}

  validates :orthogroup, presence: true,
            if: Proc.new { basis.nil? }

  # ASSOCIATIONS
  belongs_to :orthogroup, optional: true
  has_one :node

  # SCOPES
  scope :orpahan_trees, lambda {
    where(basis: :ortho).where(orthogroup: nil)
  }

  # INSTANCE METHODS
  def fetch_ortho_tree
    x = node.root.fetch_ortho_tree_as_json
    x.to_json
    #JSON.pretty_generate(self.node.root.fetch_ortho_tree_as_json)
  end

  # CLASS METHODS
  def self.fetch_trac_trees(date = 'newest')
    trait_rec_trees = Tree.where(basis: 'nuc').or(Tree.where(basis: 'pt'))

    if date == 'newest'
      nucleotide_tree = trait_rec_trees.where(published_at: trait_rec_trees.maximum('published_at')).where(basis: 'nuc')[0]
      plastid_tree = trait_rec_trees.where(published_at: trait_rec_trees.maximum('published_at')).where(basis: 'pt')[0]

      nucleotide_json = nucleotide_tree.node.root.fetch_trac_tree_as_json
      plastid_json = plastid_tree.node.root.fetch_trac_tree_as_json
    else
      nucleotide_tree = trait_rec_trees.where(published_at: date).where(basis: 'nuc')[0]
      plastid_tree = trait_rec_trees.where(published_at: date).where(basis: 'pt')[0]

      nucleotide_json = nucleotide_tree.node.root.fetch_trac_tree_as_json
      plastid_json = plastid_tree.node.root.fetch_trac_tree_as_json
    end

    newest_publishing_date = trait_rec_trees.maximum('published_at')
    publishing_dates = trait_rec_trees.distinct.pluck(:published_at)

    a = {}

    publishing_dates.each do |publishing_date|
      if publishing_date == date || (publishing_date == newest_publishing_date && date == 'newest')
        a[publishing_date] = {nuclear: nucleotide_json, plastid: plastid_json}
      else
        a[publishing_date] = {}
      end
    end

    JSON.pretty_generate(a)
  end

  def self.create_trees(types:, date: nil, tree_file: nil)
    types.each do |type|
      root = Node.process_tree_file(type: type, date: date, file_path: tree_file)
      tree = Tree.create(published_at: date, basis: type, node: root)
      return tree if type == 'ortho'
    end
  end

  # PRIVATE METHODS
  private

  def destroy_nodes
    node.subtree.destroy_all
  end
end
