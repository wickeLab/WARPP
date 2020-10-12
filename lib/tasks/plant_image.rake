namespace :plant_image do
  desc "Load plant images from inaturalist"
  task reload_inaturalist_images: :environment do |t|
    PlantImage.reload_inaturalist_images
  end

  desc "Load plant images for one family"
  task :load_inaturalist_images, [:family_name] => [:environment] do |t, args|
    PlantImage.load_images_for_family(args[:family_name])
  end
end
