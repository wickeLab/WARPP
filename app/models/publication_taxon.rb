# frozen_string_literal: true

class PublicationTaxon < ApplicationRecord
  # ASSOCIATIONS
  belongs_to :taxon
  belongs_to :publication

  # SCOPES
  scope :old_publications, lambda {
    where('updated_at < ?', 2.days.ago)
  }
end
