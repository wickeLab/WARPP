# frozen_string_literal: true

namespace :update_database do
  desc 'update recent publications'
  task publications: :environment do
    Taxon.parasites.find_each(batch_size: 1000) do |taxon|
      puts 'Updating taxon: ' + taxon.scientific_name
      taxon.fetch_publications
    end
    puts 'Destroying old relations...'
    PublicationTaxon.old_publications.destroy_all
    puts 'Destroying unlinked publications...'
    Publication.unlinked.destroy_all
  end

  desc 'update genbank entries'
  task genbank: :environment do
    GenBank.find_each(batch_size: 1000, &:ncbi_update)
  end
end
