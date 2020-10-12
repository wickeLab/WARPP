class AddBelongsToTaxa < ActiveRecord::Migration[5.2]
  def change
    add_reference :gen_banks, :taxon,
                  foreign_key: { on_delete: :cascade }

    add_reference :plant_images, :taxon,
                  foreign_key: { on_delete: :cascade }

    add_reference :submissions, :taxon,
                  foreign_key: { on_delete: :cascade }
  end
end
