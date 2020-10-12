# frozen_string_literal: true

class Habit < Lifetrait
  # CONSTANTS
  HABITS = %w[herbaceous tree].freeze

  validates_inclusion_of :information, in: HABITS
end
