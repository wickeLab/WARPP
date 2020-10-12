# frozen_string_literal: true

module TreeFormatter
  PROTEIN_TO_LOCUS_FILE = Rails.root.join('data', 'orthogroups', 'protein_to_locus.tsv')

  def newick_to_json(newick_file)
    newick_tree = Bio::Newick.new(File.read(newick_file)).tree
    json_tree = {}

    newick_tree.nodes.each do |node|
      this_node = node.name
      parent_node = newick_tree.parent(node).name
      depth = newick_tree.ancestors(node).count

      json_tree[depth] ||= {}
      json_tree[depth][parent_node] ||= []
      json_tree[depth][parent_node] << this_node
    end

=begin
    JSON.generate({
                    full_name: '',
                    id: 'root',
                    cds_locus: '',
                    children: obtain_children(newick_tree, root_node)
                  })
=end
  end

  def obtain_children(newick_tree, parent_node)
    children_entries = []
    newick_tree.children(parent_node).each do |child_node|
      node_name = child_node.name
      if node_name.strip.empty?
        full_name = locus = cds_locus = ''
      else
        full_name = node_name
        locus = full_name.split(' ')[0]
        cds_locus_entry = `grep '#{locus}' #{PROTEIN_TO_LOCUS_FILE}`
        cds_locus = cds_locus_entry.strip.empty? ? '' : cds_locus_entry.split("\t")[1]
      end

      children_entries << {
          full_name: full_name,
          id: locus,
          cds_locus: cds_locus,
          children: obtain_children(newick_tree, child_node)
      }
    end
    children_entries
  end

  def find_locus(refseq_id)
    protein_to_locus_file = Rails.root.join('data', 'orthogroups', 'protein_to_locus.tsv')
    locus_entry = `grep '#{refseq_id}' #{protein_to_locus_file}`
    return locus_entry.split("\t")[1] unless locus_entry.strip.empty?

    Retryable.retryable(tries: 3, on: [OpenURI::HTTPError, Timeout::Error, Errno::ENETUNREACH]) do
      id = HTTParty.get("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=protein&term=#{refseq_id}&retmode=json&retmax=1&api_key=#{Rails.application.credentials[:nih][:api_key]}")
      id = id['esearchresult']['idlist'][0]
      ncbi_entry = Nokogiri::XML(open("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=#{id}&retmode=xml&api_key=#{Rails.application.credentials[:nih][:api_key]}"))

      ncbi_entry.css('GBQualifier').each do |gb_qualifier|
        unless gb_qualifier.at_css('GBQualifier_name').content == 'locus_tag'
          next
        end

        locus = gb_qualifier.at_css('GBQualifier_value').content
        File.open(protein_to_locus_file, 'a+') do |f|
          f.puts "#{refseq_id}\t#{locus}"
        end

        return locus
      end
    end
  end
end
