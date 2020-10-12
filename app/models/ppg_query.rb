# frozen_string_literal: true

class PpgQuery < ApplicationRecord
  # MIXINS

  # CONSTANTS

  # ATTRIBUTES

  # MISCELLANEOUS

  # ASSOCIATIONS
  has_many :ppg_match
  belongs_to :taxon, optional: true

  has_many :ppg_matches
  has_many :ppg_jobs, through: :ppg_matches

  # VALIDATIONS
  validates :query_name, presence: true, uniqueness: true
  validates :functional_assignment, presence: true

  # SCOPES

  # CALLBACKS

  # INSTANCE METHODS
  def calculate_median_functionality(stringency)
    functionality_scores =  if stringency == 'relaxed'
                              ppg_matches.reference_data.relaxed.pluck(:functionality_score).sort
                            else
                              ppg_matches.reference_data.stringent.pluck(:functionality_score).sort
                            end

    functionality_score_count = functionality_scores.count

    if functionality_score_count > 1
      median_pos = functionality_score_count / 2.0

      median_functionality = if median_pos == median_pos.to_i
                               functionality_scores[median_pos]
                             else
                               (functionality_scores[median_pos - 0.5] + functionality_scores[median_pos + 0.5]) / 2.0
                             end
    else
      median_functionality = functionality_scores[0]
    end

    update(median_functionality_score: median_functionality)
  end

  # CLASS METHODS
  # PRIVATE METHODS
end
