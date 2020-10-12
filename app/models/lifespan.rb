class Lifespan < Lifetrait
  # CONSTANTS
  LIFESPANS = %w[annual biennial perennial].freeze

  validates_inclusion_of :information, in: LIFESPANS
end
