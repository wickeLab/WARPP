# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lifestyle, type: :model do
  context 'validates' do
    it 'information is lifestyle' do
      taxon = Taxon.create(scientific_name: 'Striga')
      lifestyle_info = Lifestyle.new(taxon: taxon, information: 'annual')

      expect(lifestyle_info).to_not be_persisted
    end
  end
end
