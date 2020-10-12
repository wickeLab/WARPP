namespace :tree do
  desc 'Load tree data into database'
  task :create_trait_tree, [:publishing_date] => [:environment] do |_t, args|
    Tree.create_trees(date: args[:publishing_date], types: %w[nuc pt])
  end

  desc 'Replace ortho tree'
  task replace_ortho_trees: :environment do |_t|
    Orthogroup.overwrite_orthogroups
  end

  desc 'Transfer node ancestry to custom ancestry'
  task transfer_ancestry: :environment do |_t|
    Node.find_each(batch_size: 1000) do |node|
      parent_node = node.parent.id
      child_node = node.children.id

      node.update(parent_node: parent_node, child_node: child_node)
    end
  end

  desc 'Name genera in trait reconstruction tree'
  task name_genera: :environment do |_t|
    Tree.where('orthogroup_id IS NULL').each do |tree|
      tree.node.update(node_identifier: 'Orobanchaceae')
      subtree = tree.node.subtree
      genera = subtree.species.pluck(:node_identifier).map { |species| species.split(' ')[0] }.uniq
      genera.each do |genus|
        genus_members = subtree.where('node_identifier ~* ?', "#{genus}\s.+")
        ids = genus_members.map { |group_member| group_member.ancestors.pluck(:id, :ancestry_depth) }.flatten(1)

        ids_count = ids.each_with_object(Hash.new(0)) do |id_depth, new_hash|
          new_hash[id_depth] += 1
        end

        genus_members_count = genus_members.count
        last_common_ancestor_id = ids_count.select { |_id_depth, num| num == genus_members_count }.keys.sort_by { |_k,v| -v }.first[0]

        last_common_ancestor = subtree.find(last_common_ancestor_id)

        ancestor_identifier = last_common_ancestor.node_identifier
        if ancestor_identifier[/[A-Z][a-z]+\s[a-z]+/] && !ancestor_identifier.include?(genus)
          last_common_ancestor.update(node_identifier: "#{ancestor_identifier}|#{genus}")
        else
          last_common_ancestor.update(node_identifier: genus)
        end
      end
    end
  end
end
