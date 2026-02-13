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

ActiveRecord::Schema[8.0].define(version: 2026_02_13_102305) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_keys", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "description"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_api_keys_on_key", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "external_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider"
    t.string "external_user_id"
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "token_expires_at"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_shop_id"
    t.string "external_shop_name"
    t.jsonb "settings", default: {}
    t.index ["user_id"], name: "index_external_accounts_on_user_id"
  end

  create_table "login_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.string "purpose"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_login_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_login_tokens_on_user_id"
  end

  create_table "queue_items", force: :cascade do |t|
    t.string "name"
    t.string "reference_id"
    t.integer "status", default: 0, null: false
    t.string "priority"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "due_date"
    t.text "notes"
    t.integer "user_id", null: false
    t.bigint "order_id"
    t.bigint "order_item_id"
    t.integer "quantity", default: 1, null: false
    t.jsonb "variations"
    t.string "sku"
    t.index ["user_id"], name: "index_queue_items_on_user_id"
  end

  create_table "sync_logs", force: :cascade do |t|
    t.bigint "external_account_id", null: false
    t.string "status"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text "message"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_account_id"], name: "index_sync_logs_on_external_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "api_keys", "users"
  add_foreign_key "external_accounts", "users"
  add_foreign_key "login_tokens", "users"
  add_foreign_key "queue_items", "users"
  add_foreign_key "sync_logs", "external_accounts"
end
