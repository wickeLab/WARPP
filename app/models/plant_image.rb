class PlantImage < ApplicationRecord
  # creative commons licenses should be fine -> sharing with attribution
  ALLOWED_LICENSES = %w[CC-BY CC-BY-NC CC-BY-SA CC-BY-ND CC-BY-NC-SA CC-BY-NC-ND].freeze
  LICENSES = { 'CC-BY' => 'https://creativecommons.org/licenses/by/4.0/',
               'CC-BY-NC' => 'https://creativecommons.org/licenses/by-nc/4.0/',
               'CC-BY-SA' => 'https://creativecommons.org/licenses/by-sa/4.0/',
               'CC-BY-ND' => 'https://creativecommons.org/licenses/by-nd/4.0/',
               'CC-BY-NC-SA' => 'https://creativecommons.org/licenses/by-nc-sa/4.0/',
               'CC-BY-NC-ND' => 'https://creativecommons.org/licenses/by-nc-nd/4.0/' }.freeze

  # SCOPES
  scope :userless_entries, lambda {
    where(user: nil)
  }

  scope :inaturalist_entries, lambda {
    where(publisher: 'iNaturalist')
  }

  # ASSOCIATIONS
  belongs_to :taxon
  belongs_to :user, optional: true

  has_one_attached :image

  # INSTANCE METHODS
  def attribution_to_hash
    {
      creator: attribution,
      publisher: publisher,
      reference: reference_url,
      license_url: LICENSES[license],
      license: license,
      created: observed_on,
      location: location_data
    }
  end

  # CLASS METHODS
  def self.reload_inaturalist_images
    Taxon.parasites.each do |taxon|
      taxon.plant_images.inaturalist_entries.destroy_all
      taxon.fetch_photos_from_inaturalist
    end
  end

  def self.load_images_for_family(family)
    Taxon.root(family).subtree.species.each(&:fetch_photos_from_inaturalist)
  end
end
