# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Taxon, type: :model do
  context 'when destroyed' do
    it 'destroys associations' do
      taxon = Taxon.create(scientific_name: 'Striga')
      gen_bank_entry = GenBank.create(taxon: taxon)

      taxon.destroy

      expect { gen_bank_entry.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'destroys descendants' do
      taxon = Taxon.create(scientific_name: 'Striga')
      taxon_child = Taxon.create(scientific_name: 'Striga asiatica', parent: taxon)

      taxon.destroy

      expect { taxon_child.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
