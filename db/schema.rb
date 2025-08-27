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

ActiveRecord::Schema[8.0].define(version: 2025_08_27_015122) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "banks", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_banks_on_name"
  end

  create_table "customers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "source_currency", null: false
    t.string "target_currency", null: false
    t.decimal "rate", precision: 18, scale: 10, default: "0.0", null: false
    t.decimal "cost_rate", precision: 18, scale: 10, default: "0.0", null: false
    t.integer "amount", default: 0, null: false
    t.integer "total", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "profit", default: 0.0
    t.string "sender_type", null: false
    t.bigint "sender_id", null: false
    t.string "receiver_type", null: false
    t.bigint "receiver_id", null: false
    t.index ["receiver_type", "receiver_id"], name: "index_transactions_on_receiver"
    t.index ["sender_type", "sender_id"], name: "index_transactions_on_sender"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "sessions", "users"
end
