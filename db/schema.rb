# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_08_13_180642) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "job_chunks", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.integer "chunk_index", null: false
    t.text "content", null: false
    t.string "content_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding", limit: 1536
    t.index [ "job_id", "chunk_index" ], name: "index_job_chunks_on_job_id_and_chunk_index", unique: true
    t.index [ "job_id" ], name: "index_job_chunks_on_job_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.string "title", null: false
    t.string "company_name"
    t.string "source", null: false
    t.string "source_url", null: false
    t.text "description"
    t.datetime "published_at"
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "source", "source_url" ], name: "index_jobs_on_source_and_source_url", unique: true
  end

  create_table "source_import_states", force: :cascade do |t|
    t.string "source", null: false
    t.datetime "initial_import_completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "source" ], name: "index_source_import_states_on_source", unique: true
  end

  add_foreign_key "job_chunks", "jobs"
end
