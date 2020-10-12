class AddSpeciesReferenceToSubmissions < ActiveRecord::Migration[5.2]
  def up
    remove_column :submissions, :species
    add_reference :submissions, :taxonomic_level
  end

  def down
    remove_reference :submissions, :taxonomic_level
    add_column :submissions, :species, :string
  end
end
