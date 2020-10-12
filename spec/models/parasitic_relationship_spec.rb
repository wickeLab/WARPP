require 'rails_helper'

RSpec.describe ParasiticRelationship, type: :model do
  context 'on adding parasite' do
    it 'creates parasitic relationship' do
      host = Taxon.create(scientific_name: 'host')
      parasite = Taxon.create(scientific_name: 'parasite')

      host.parasites << parasite

      expect(ParasiticRelationship.where(host: host, parasite: parasite).exists?).to be_truthy
    end
  end

  context 'on taxon delete' do
    it 'cascades' do
      host = Taxon.create(scientific_name: 'host')
      parasite = Taxon.create(scientific_name: 'parasite')

      parasitic_relationship = ParasiticRelationship.create(host: host, parasite: parasite)
      host.destroy

      expect { parasitic_relationship.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
