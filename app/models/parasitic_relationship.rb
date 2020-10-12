# frozen_string_literal: true

class ParasiticRelationship < ApplicationRecord
  # ASSOCIATIONS
  belongs_to :parasite, class_name: 'Taxon'
  belongs_to :host, class_name: 'Taxon'

  has_and_belongs_to_many :publications
end
