# frozen_string_literal: true

class PpgMatch < ApplicationRecord
  # MIXINS

  # CONSTANTS

  # ATTRIBUTES

  # MISCELLANEOUS
  enum mode: {
    stringent: 'stringent',
    relaxed: 'relaxed'
  }, _suffix: :mode

  # ASSOCIATIONS
  belongs_to :ppg_job, optional: true
  belongs_to :ppg_query

  # VALIDATIONS
  validates :target, presence: true
  validates :functionality_score, numericality: true, if: :functionality_score

  # SCOPES
  scope :reference_data, lambda {
    where('ppg_job_id IS NULL')
  }

  scope :relaxed, lambda {
    where('cast(stringency AS TEXT) LIKE ?', 'relaxed')
  }

  scope :stringent, lambda {
    where('cast(stringency AS TEXT) LIKE ?', 'stringent')
  }

  # CALLBACKS
  after_create :calculate_median_functionality,
               if: proc { |match| match.ppg_job.nil? }

  # INSTANCE METHODS
  # CLASS METHODS
  # PRIVATE METHODS
  private

  def calculate_median_functionality
    ppg_query.calculate_median_functionality(stringency)
  end
end
