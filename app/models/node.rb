class Node < ApplicationRecord

  # ASSOCIATIONS
  belongs_to :tree, optional: true

  has_ancestry cache_depth: true

  # SCOPES
  scope :orphan_nodes, lambda {
    Node.roots.where(tree: nil)
  }

  scope :species, lambda {
    where('node_identifier ~* ?', '^[A-Z][a-z]+\s[a-z]+$')
  }

  scope :families, lambda {
    where('node_identifier ~* ?', '^[A-Za-z]*eae$')
  }

  include PgSearch::Model
  pg_search_scope :kinda_spelled_like,
                  against: :node_identifier,
                  using: :trigram,
                  ranked_by: ':trigram'

  # INSTANCE METHODS
  def fetch_trac_tree_as_json
    x = self.subtree

    a = x.arrange_serializable do |parent, children|
      {
        name: parent.node_identifier,
        lifespan: [
          {
            "itemLabel": 'annual',
            "itemValue": parent.probability_lifespan[0]
          },
          {
            "itemLabel": 'biennial',
            "itemValue": parent.probability_lifespan[1]
          },
          {
            "itemLabel": 'perennial',
            "itemValue": parent.probability_lifespan[-1]
          }
        ],
        lifestyle: [
          {
            "itemLabel": 'autotroph',
            "itemValue": parent.probability_lifestyle[0]
          },
          {
            "itemLabel": 'facultative',
            "itemValue": parent.probability_lifestyle[1]
          },
          {
            "itemLabel": 'obligate',
            "itemValue": parent.probability_lifestyle[2]
          },
          {
            "itemLabel": 'holoparasitic',
            "itemValue": parent.probability_lifestyle[-1]
          }
        ],
        children: children
      }
    end
    a[0]
  end

  def fetch_ortho_tree_as_json
    x = self.subtree

    a = x.to_depth(250).arrange_serializable do |parent, children|
      if parent.depth < 250
        {
          name: parent.node_identifier,
          children: children,
          more: false,
          id: parent.id
        }
      elsif parent.depth == 250
        {
          name: parent.node_identifier,
          children: children,
          more: true,
          id: parent.id
        }
      end
    end
    a[0]
  end

  def recursive_child_obtaining_from_newick(newick_tree, parent_node)
    newick_tree.children(parent_node).each do |child_node|
      child_entry = Node.create(node_identifier: child_node.name, parent: self)
      child_entry.recursive_child_obtaining_from_newick(newick_tree, child_node)
    end
  end

  # CLASS METHODS
  def self.recursive_json_from_tree(nodes)
    nodes.map do |node, sub_nodes|
      { name: node.node_identifier, children: self.recursive_json_from_tree(sub_nodes).compact }
    end
  end

  def self.read_probabilities(date, type, trait)
    file_path = Rails.root.join('data', 'trait_reconstruction_trees', date, "#{trait}_#{type}.txt")
    node_to_probs = {}
    CSV.open(file_path, headers: true, col_sep: "\t").each do |row|
      values = row[1..-1].map(&:to_f)
      node_to_probs[row['node'].gsub('Node', '')] = values
    end
    return node_to_probs
  end


  def self.fetch_species_info(node_identifier, lifestyle_prob, lifespan_prob)
    lifestyles = %w[autotroph facultative obligate holoparasitic unknown]
    lifespans = %w[annual biennial perennial unknown]
    species_entry = TaxonomicLevel.find_by scientific_name: node_identifier

    unless lifestyle_prob
      lifestyle_prob = [0, 0, 0, 0]

      if species_entry&.lifestyle
        lifestyle_prob[lifestyles.index(species_entry.lifestyle)] = 1
      end
    end

    unless lifespan_prob
      lifespan_prob = [0, 0, 0]

      if species_entry&.lifespan
        lifespan_prob[lifespans.index(species_entry.lifespan)] = 1
      end
    end

    return lifestyle_prob, lifespan_prob
  end


  def self.process_tree_file(file_path:, type:, date:)
    if date # trait tree
      lifestyle_probs = Node.read_probabilities(date, type, 'lifestyle')
      lifespan_probs = Node.read_probabilities(date, type, 'lifespan')
      file_path = Rails.root.join('data', 'trait_reconstruction_trees', date.upcase, "OROB_#{type}.nex")
      return process_nexus_file(file_path, lifestyle_probs, lifespan_probs)
    else # ortho tree
      newick_tree = Bio::Newick.new(File.read(file_path)).tree
      return process_newick_tree(newick_tree)
    end
  end

  def self.process_nexus_file(file_path, lifestyle_probs, lifespan_probs)
    nexus = Bio::Nexus.new(File.read(file_path))

    tree_block = nexus.get_trees_blocks[ 0 ]

    reading = false
    number_to_taxon = {}

    # Node Translation (numbers to taxa)
    File.open(file_path).each do |line|
      if reading && line.strip == ';'
        break
      end

      if reading
        split_line = line.strip.gsub(',', '').split
        number_to_taxon[split_line[0]] = split_line[-1].split('_', 2)[-1].gsub('_', ' ')
      end

      if line.include?('translate')
        reading = true
      end
    end

    newick_tree = tree_block.get_tree(0)
    return process_newick_tree(newick_tree, number_to_taxon, lifestyle_probs, lifespan_probs)
  end

  def self.process_newick_tree(newick_tree, number_to_taxon = {}, lifestyle_probs = nil, lifespan_probs = nil)
    if lifestyle_probs
      node_identifier_to_id = {}

      newick_tree.each_node do |node|
        parent_node = newick_tree.parent(node)

        ancestor_name = parent_node.name if parent_node
        ancestor_name.gsub!('.0', '') if ancestor_name

        if !number_to_taxon.include?(node.name)
          target_name = node.name
        else
          target_name = number_to_taxon[node.name]
        end

        if target_name && !target_name.empty?
          target_name.gsub!('.0', '')

          ancestor = Node.find(node_identifier_to_id[ancestor_name]) if node_identifier_to_id.include?(ancestor_name)
          node_instance = Node.find(node_identifier_to_id[target_name]) if node_identifier_to_id.include?(target_name)

          if !ancestor && ancestor_name && !ancestor_name.empty?
            if !number_to_taxon.empty?
              lifestyle_prob, lifespan_prob = fetch_species_info(ancestor_name, lifestyle_probs[ancestor_name], lifespan_probs[ancestor_name])
              ancestor = Node.create(node_identifier: ancestor_name, probability_lifestyle: lifestyle_prob, probability_lifespan: lifespan_prob)
            else
              ancestor = Node.create(node_identifier: ancestor_name)
            end
            node_identifier_to_id[ancestor_name] = ancestor.id
          end

          unless node_instance
            if !number_to_taxon.empty?
              lifestyle_prob, lifespan_prob = fetch_species_info(target_name, lifestyle_probs[target_name], lifespan_probs[target_name])
              node_instance = Node.create(node_identifier: target_name, probability_lifestyle: lifestyle_prob, probability_lifespan: lifespan_prob)
            else
              node_instance = Node.create(node_identifier: target_name)
            end
            node_identifier_to_id[target_name] = node_instance.id
          end

          unless node_instance.parent
            node_instance.update(parent: ancestor)
          end
        end
      end
    else
      root_node = newick_tree.root
      root_entry = Node.create(node_identifier: root_node.name)
      begin
        root_entry.recursive_child_obtaining_from_newick(newick_tree, root_node)
      rescue => e
        p e.inspect
      end
    end

    Node.last.root.subtree.rebuild_depth_cache!
    return Node.last.root
  end
end
