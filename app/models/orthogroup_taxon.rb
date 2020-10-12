class OrthogroupTaxon < ApplicationRecord
  # MIXINS
  include TreeFormatter

  # ASSOCIATIONS
  belongs_to :taxon
  belongs_to :orthogroup

  # INSTANCE METHODS
  def fetch_loci
    new_loci = []
    entries.each do |og_member|
      refseq_id = og_member.split(' ')[0]
      begin
        protein_to_locus_file = Rails.root.join('data', 'orthogroups', 'protein_to_locus.tsv')
        locus_entry = `grep '#{refseq_id}' #{protein_to_locus_file}`
        locus = locus_entry.split("\t")[1] unless locus_entry.strip.empty?

        # locus = find_locus(refseq_id)
        new_loci << locus if locus&.length&.positive?
      rescue # OpenURI::HTTPError, JSON::ParserError
        p refseq_id
      end
    end
    update(loci: new_loci)
  end

  def fetch_members_as_json
    {
      taxon: taxon.scientific_name,
      children: members.values
    }
  end

  # CLASS METHODS
  def self.protein_to_locus(protein_accession)
    protein_to_locus_file = Rails.root.join('data', 'orthogroups', 'protein_to_locus.tsv')
    locus_entry = `grep '#{protein_accession}' #{protein_to_locus_file}`.strip
    locus_entry.empty? ? nil : locus_entry.split("\t")[1]
  end
end
