class Lifestyle < Lifetrait
  # CONSTANTS
  LIFESTYLES = %w[autotroph facultative obligate holoparasitic].freeze

  validates_inclusion_of :information, in: LIFESTYLES
end
