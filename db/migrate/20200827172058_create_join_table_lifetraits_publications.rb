class CreateJoinTableLifetraitsPublications < ActiveRecord::Migration[5.2]
  def change
    create_join_table :lifetraits, :publications do |t|
      t.index %i[lifetrait_id publication_id],
              name: :idx_trait_pubs_lifetrait_publication,
              unique: true
      t.index %i[publication_id lifetrait_id],
              name: :idx_trait_pubs_publication_lifetrait,
              unique: true
    end
  end
end
