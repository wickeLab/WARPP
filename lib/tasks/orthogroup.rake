# frozen_string_literal: true

namespace :orthogroup do
  desc 'reattach newick and fasta files to all OGs'
  task reattach_files: :environment do
    Orthogroup.find_each(batch_size: 1000) do |orthogroup|
      id = orthogroup.identifier

      tree = Rails.root.join('data', 'orthogroups', 'orthogroup_trees', "#{id}_tree.txt")
      fasta = Rails.root.join('data', 'orthogroups', 'orthogroup_sequences', "#{id}.fa")

      orthogroup.tree_file.attach(io: File.open(tree), filename: "#{id}_tree.txt", content_type: 'text/plain')

      if fasta.file?
        orthogroup.sequence_file.attach(io: File.open(fasta), filename: "#{id}.fa", content_type: 'text/plain')
      end
    end
  end

  desc 'Fetch loci'
  task fetch_loci: :environment do
    Taxon::AVAILABLE_GENOME_BROWSERS.each do |scientific_name|
      taxon_id = Taxon.find_by(scientific_name: scientific_name).id
      OrthogroupTaxon.where(taxon_id: taxon_id).each(&:fetch_loci)
    end
  end

  desc 'Load member json from entries column for all OGs'
  task load_members: :environment do
    progressbar = ProgressBar.create(format: "%a %b\u{15E7}%i %p%% %t",
                                     progress_mark: ' ',
                                     remainder_mark: "\u{FF65}",
                                     starting_at: 10,
                                     total: OrthogroupTaxon.all.length)

    OrthogroupTaxon.find_each(batch_size: 1000).each do |orthogroup_taxon|
      new_members = {}
      orthogroup_taxon.entries.each do |entry|
        protein_accession = entry.split(' ')[0]

        cds_locus = OrthogroupTaxon.protein_to_locus(protein_accession)

        new_members[protein_accession] ||=
          {
            ncbi_accession: protein_accession,
            definition: entry.split(' ', 2)[-1],
            cds_locus: cds_locus
          }
      end

      orthogroup_taxon.update(members: new_members)
      progressbar.increment
    end
  end

  desc 'Loads function realm from A. thaliana entry for all OGs'
  task load_function_realm: :environment do
    Orthogroup.find_each(batch_size: 1000, &:set_function_realm)
  end
end
