# frozen_string_literal: true

class Lifetrait < ApplicationRecord
  # CONSTANTS
  # LIFETRAIT_VALUES = Lifespan::LIFESPANS + Lifestyle::LIFESTYLES + Habit::HABITS
  LIFETRAIT_COUNT = 5.0

  # ASSOCIATIONS
  belongs_to :taxon
  has_and_belongs_to_many :publications

  def add_references(references)
    references.each do |reference|
      next unless reference != 'personal observation'

      publication = Publication.where(doi: reference).first_or_create
      publications << publication if publication.persisted?
    end
  end
end
