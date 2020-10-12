require 'rails_helper'

RSpec.describe Publication, type: :model do
  context 'relations' do
    it 'recent_publication' do
      recent_publication = Publication.create(doi: '10.11646/zootaxa.4508.2.9')
      host_taxon = TaxonomicLevel.create(scientific_name: 'host_taxon')

      host_taxon.recent_publications << recent_publication

      expect(Publication.not_recent.count).to eq(0)
    end

    it 'parasitic_reference' do
      parasitic_relationship_reference = Publication.create(doi: '10.1111/j.1759-6831.2012.00180.x')
      host_taxon = TaxonomicLevel.create(scientific_name: 'host_taxon')
      parasitic_taxon = TaxonomicLevel.create(scientific_name: 'host_taxon')
      parasitic_relationship = ParasiticRelationship.create(host: host_taxon, parasite: parasitic_taxon)

      parasitic_relationship.publications << parasitic_relationship_reference

      expect(Publication.no_parasitic_relationship.count).to eq(0)
    end

    it 'no_trait_info' do
      taxonomic_info_reference = Publication.create(doi: '10.11646/zootaxa.4508.2.9')
      host_taxon = TaxonomicLevel.create(scientific_name: 'host_taxon')
      taxon_information = TaxonInformation.create(taxonomic_level: host_taxon, information_type: 'lifespan', information: 'annual')

      taxon_information.publications << taxonomic_info_reference

      expect(Publication.no_trait_info.count).to eq(0)
    end

    it 'unlinked' do
      Publication.create(doi: '10.1890/11-0501.1')

      expect(Publication.unlinked.count).to eq(1)
    end

    it 'only_unlinked' do
      Publication.create(doi: '10.1890/11-0501.1') # unlinked publication
      recent_publication = Publication.create(doi: '10.11646/zootaxa.4508.2.9')
      parasitic_relationship_reference = Publication.create(doi: '10.1111/j.1759-6831.2012.00180.x')
      taxonomic_information_reference = Publication.create(doi: '10.1016/j.bse.2020.104039')
      host_taxon = TaxonomicLevel.create(scientific_name: 'host_taxon')
      parasitic_taxon = TaxonomicLevel.create(scientific_name: 'host_taxon')
      parasitic_relationship = ParasiticRelationship.create(host: host_taxon, parasite: parasitic_taxon)
      taxon_information = TaxonInformation.create(taxonomic_level: host_taxon, information_type: 'lifespan', information: 'annual')

      host_taxon.recent_publications << recent_publication
      parasitic_relationship.publications << parasitic_relationship_reference
      taxon_information.publications << taxonomic_information_reference

      expect(Publication.unlinked.count).to eq(1)
    end
  end
end
