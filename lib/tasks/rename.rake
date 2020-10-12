# frozen_string_literal: true

require 'ruby-progressbar'

def create_taxon_entry(taxonomic_level)
  scientific_name = taxonomic_level.scientific_name
  authorship = taxonomic_level.authorship
  parent = taxonomic_level.parent

  if parent
    parent_scientific_name = parent.scientific_name
    taxon_parent = Taxon.find_by(scientific_name: parent_scientific_name) || create_taxon_entry(parent)
  end

  taxon = Taxon.find_by(scientific_name: scientific_name) || Taxon.create(scientific_name: scientific_name,
                                                                          authorship: authorship,
                                                                          parent: taxon_parent,
                                                                          gen_bank: taxonomic_level.gen_bank)

  # PARASITIC RELATIONSHIPS
  taxonomic_level.parasitized_species.each do |pr_entry|
    host_level = pr_entry.host
    host = Taxon.find_by(scientific_name: host_level.scientific_name) || create_taxon_entry(host_level)

    host_parasite_entry = HostParasiteJoin.create(host: host, parasite: taxon)
    pr_entry.publications.each do |publication|
      host_parasite_entry.publications << publication
    end
  end

  taxonomic_level.hosted_species.each do |pr_entry|
    parasite_level = pr_entry.parasite
    parasite = Taxon.find_by(scientific_name: parasite_level.scientific_name) || create_taxon_entry(parasite_level)

    host_parasite_entry = HostParasiteJoin.create(host: taxon, parasite: parasite)
    pr_entry.publications.each do |publication|
      host_parasite_entry.publications << publication
    end
  end

  # LIFETRAITS
  taxon_informations = taxonomic_level.taxon_informations
  taxon_informations.each do |information_piece|
    case information_piece.information_type
    when 'lifestyle'
      lifetrait = Lifestyle.create(information: information_piece.information, taxon: taxon)
    when 'lifespan'
      lifetrait = Lifespan.create(information: information_piece.information, taxon: taxon)
    when 'habit'
      lifetrait = Habit.create(information: information_piece.information, taxon: taxon)
    when 'chromosome_number'
      lifetrait = ChromosomeNumber.create(information: information_piece.information, taxon: taxon)
    when 'genome_size'
      lifetrait = GenomeSize.create(information: information_piece.information, taxon: taxon)
    end

    information_piece.publications.each do |publication|
      lifetrait.publications << publication
    end
  end

  # SUBMISSIONS
  Submission.where(taxonomic_level: taxonomic_level).each do |submission|
    submission.update(taxon: taxon)
  end

  # PLANT IMAGES
  taxonomic_level.plant_images.each do |image|
    image.update(taxon: taxon)
  end

  # PUBLICATIONS
  taxonomic_level.recent_publications.each do |pub|
    taxon.publications << pub
  end

  # ORTHOGROUPS
  taxonomic_level.orthogroup_taxonomic_levels.each do |og_tax_level|
    OrthogroupTaxon.create(taxon: taxon,
                           entries: og_tax_level.functions,
                           identifier: og_tax_level.identifier,
                           orthogroup: og_tax_level.orthogroup)
  end

  taxon
end

namespace :rename do
  desc 'Load taxonomic level data into taxon model'
  task taxonomic_level_to_taxon: :environment do |_t|
    progressbar = ProgressBar.create(format: "%a %b\u{15E7}%i %p%% %t",
                                     progress_mark: ' ',
                                     remainder_mark: "\u{FF65}",
                                     starting_at: 10,
                                     total: TaxonomicLevel.all.length)

    TaxonomicLevel.all.each do |taxonomic_level|
      next if Taxon.find_by scientific_name: taxonomic_level.scientific_name

      create_taxon_entry(taxonomic_level)
      progressbar.increment
    end
    Taxon.rebuild_depth_cache!
  end

  desc 'Reload parasitic relationships from host_parasite_join'
  task reload_parasitic_relationships: :environment do |_t|
    progressbar = ProgressBar.create(format: "%a %b\u{15E7}%i %p%% %t",
                                     progress_mark: ' ',
                                     remainder_mark: "\u{FF65}",
                                     starting_at: 10,
                                     total: HostParasiteJoin.all.length)

    HostParasiteJoin.all.each do |host_parasite|
      pr = ParasiticRelationship.new
      pr.host = host_parasite.host
      pr.parasite = host_parasite.parasite
      host_parasite.publications.each do |pub|
        pr.publications << pub
      end
      pr.save

      progressbar.increment
    end
  end
end
