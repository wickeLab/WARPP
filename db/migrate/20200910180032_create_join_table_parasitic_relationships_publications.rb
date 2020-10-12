class CreateJoinTableParasiticRelationshipsPublications < ActiveRecord::Migration[5.2]
  def change
    create_join_table :parasitic_relationships, :publications do |t|
      t.index %i[parasitic_relationship_id publication_id],
              name: :idx_join_pr_publication,
              unique: true
      t.index %i[publication_id parasitic_relationship_id],
              name: :idx_join_publication_pr
    end
  end
end
