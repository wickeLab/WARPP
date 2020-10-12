# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_09_13_111427) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "blast_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "blast_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chromosome_numbers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gen_banks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "est"
    t.integer "mtdna"
    t.integer "others"
    t.integer "plastome"
    t.integer "sra"
    t.boolean "whole_genome"
    t.bigint "taxon_id"
    t.index ["taxon_id"], name: "index_gen_banks_on_taxon_id"
  end

  create_table "genome_sizes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "habits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lifespans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lifestyles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lifetraits", force: :cascade do |t|
    t.bigint "taxon_id"
    t.text "information", null: false
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["taxon_id"], name: "index_lifetraits_on_taxon_id"
  end

  create_table "lifetraits_publications", id: false, force: :cascade do |t|
    t.bigint "lifetrait_id", null: false
    t.bigint "publication_id", null: false
    t.index ["lifetrait_id", "publication_id"], name: "idx_trait_pubs_lifetrait_publication", unique: true
    t.index ["publication_id", "lifetrait_id"], name: "idx_trait_pubs_publication_lifetrait", unique: true
  end

  create_table "nodes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ancestry"
    t.integer "ancestry_depth", default: 0
    t.string "node_identifier"
    t.bigint "tree_id"
    t.float "probability_lifespan", default: [], array: true
    t.float "probability_lifestyle", default: [], array: true
    t.index ["tree_id"], name: "index_nodes_on_tree_id"
  end

  create_table "orthogroup_taxons", force: :cascade do |t|
    t.bigint "taxon_id"
    t.bigint "orthogroup_id"
    t.text "entries", default: [], array: true
    t.text "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "loci", default: [], array: true
    t.jsonb "members", default: {}, null: false
    t.index ["identifier", "orthogroup_id"], name: "index_orthogroup_taxons_on_identifier_and_orthogroup_id", unique: true
    t.index ["identifier"], name: "index_orthogroup_taxons_on_identifier"
    t.index ["members"], name: "index_orthogroup_taxons_on_members", using: :gin
    t.index ["orthogroup_id"], name: "index_orthogroup_taxons_on_orthogroup_id"
    t.index ["taxon_id"], name: "index_orthogroup_taxons_on_taxon_id"
  end

  create_table "orthogroups", force: :cascade do |t|
    t.string "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "function_realm", default: ["unknown"], array: true
    t.index ["identifier"], name: "index_orthogroups_on_identifier", unique: true
  end

  create_table "parasitic_relationships", force: :cascade do |t|
    t.bigint "parasite_id"
    t.bigint "host_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_parasitic_relationships_on_host_id"
    t.index ["parasite_id"], name: "index_parasitic_relationships_on_parasite_id"
  end

  create_table "parasitic_relationships_publications", id: false, force: :cascade do |t|
    t.bigint "parasitic_relationship_id", null: false
    t.bigint "publication_id", null: false
    t.index ["parasitic_relationship_id", "publication_id"], name: "idx_join_pr_publication", unique: true
    t.index ["publication_id", "parasitic_relationship_id"], name: "idx_join_publication_pr"
  end

# Could not dump table "plant_images" because of following StandardError
#   Unknown type 'license_types' for column 'license'

  create_table "ppg_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ppg_runs", force: :cascade do |t|
    t.integer "maxintron"
    t.integer "minintron"
    t.text "stringency", default: ["stringent"], array: true
    t.float "stringency_value"
    t.integer "best_hits"
    t.boolean "out_identity", default: false
    t.boolean "out_frame_shifts", default: false
    t.boolean "out_missing_genes", default: false
    t.boolean "out_sequences", default: false
    t.boolean "out_annotation", default: false
    t.boolean "email_notification", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "publication_taxons", force: :cascade do |t|
    t.bigint "publication_id"
    t.bigint "taxon_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publication_id"], name: "index_publication_taxons_on_publication_id"
    t.index ["taxon_id"], name: "index_publication_taxons_on_taxon_id"
  end

  create_table "publications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "title"
    t.integer "year"
    t.text "authors", default: [], array: true
    t.string "doi"
    t.index ["authors"], name: "index_publications_on_authors", using: :gin
  end

# Could not dump table "server_jobs" because of following StandardError
#   Unknown type 'server_job_status' for column 'status'

# Could not dump table "submissions" because of following StandardError
#   Unknown type 'submission_status' for column 'status'

  create_table "taxons", force: :cascade do |t|
    t.string "ancestry"
    t.integer "ancestry_depth", default: 0
    t.citext "scientific_name", null: false
    t.string "authorship"
    t.float "information_score", default: 0.0
    t.float "reliability_score", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestry"], name: "index_taxons_on_ancestry"
    t.index ["scientific_name"], name: "index_taxons_on_scientific_name", unique: true
  end

  create_table "trees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "published_at"
    t.integer "basis"
    t.bigint "orthogroup_id"
    t.index ["orthogroup_id"], name: "index_trees_on_orthogroup_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.string "user_name"
    t.float "reliablity_score"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["user_name"], name: "index_users_on_user_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "gen_banks", "taxons", on_delete: :cascade
  add_foreign_key "lifetraits", "taxons", on_delete: :cascade
  add_foreign_key "nodes", "trees"
  add_foreign_key "orthogroup_taxons", "orthogroups", on_delete: :cascade
  add_foreign_key "orthogroup_taxons", "taxons", on_delete: :cascade
  add_foreign_key "parasitic_relationships", "taxons", column: "host_id", on_delete: :cascade
  add_foreign_key "parasitic_relationships", "taxons", column: "parasite_id", on_delete: :cascade
  add_foreign_key "plant_images", "taxons", on_delete: :cascade
  add_foreign_key "publication_taxons", "publications", on_delete: :cascade
  add_foreign_key "publication_taxons", "taxons", on_delete: :cascade
  add_foreign_key "server_jobs", "users"
  add_foreign_key "submissions", "taxons", on_delete: :cascade
  add_foreign_key "submissions", "users"
  add_foreign_key "trees", "orthogroups"
end
