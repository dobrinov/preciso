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

ActiveRecord::Schema[8.1].define(version: 2026_06_09_075207) do
  create_table "abouts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.text "lead"
    t.string "signature"
    t.string "studio"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "campaign_items", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.datetime "created_at", null: false
    t.string "discount_kind", default: "fixed", null: false
    t.integer "item_id", null: false
    t.string "kind", default: "product", null: false
    t.integer "percent_off"
    t.integer "sale_price"
    t.datetime "updated_at", null: false
    t.index ["campaign_id", "kind", "item_id"], name: "idx_campaign_items_unique", unique: true
    t.index ["campaign_id"], name: "index_campaign_items_on_campaign_id"
    t.index ["kind", "item_id"], name: "index_campaign_items_on_kind_and_item_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.boolean "all_products", default: false, null: false
    t.text "blurb"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "percent_off"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_campaigns_on_active"
    t.index ["slug"], name: "index_campaigns_on_slug", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "blurb"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.string "slug", null: false
    t.string "tone"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "collection_memberships", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0
    t.integer "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "product_id"], name: "index_collection_memberships_on_collection_id_and_product_id", unique: true
    t.index ["collection_id"], name: "index_collection_memberships_on_collection_id"
    t.index ["product_id"], name: "index_collection_memberships_on_product_id"
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_collections_on_slug", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "label"
    t.string "name"
    t.datetime "occurred_at", null: false
    t.string "page_key"
    t.boolean "piece", default: false
    t.string "sid"
    t.integer "total"
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["occurred_at"], name: "index_events_on_occurred_at"
  end

  create_table "home_pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "footer_blurb"
    t.string "hero_accent"
    t.string "hero_eyebrow"
    t.text "hero_subtext"
    t.text "hero_title"
    t.string "maker_eyebrow"
    t.text "maker_text"
    t.string "maker_title"
    t.datetime "updated_at", null: false
  end

  create_table "order_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "item_id"
    t.string "kind", default: "product", null: false
    t.string "name"
    t.integer "order_id", null: false
    t.integer "price", default: 0, null: false
    t.integer "qty", default: 1, null: false
    t.datetime "updated_at", null: false
    t.integer "variant_id"
    t.string "variant_label"
    t.index ["order_id"], name: "index_order_lines_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_email"
    t.string "customer_name"
    t.string "customer_phone"
    t.text "note"
    t.string "number", null: false
    t.string "status", default: "new", null: false
    t.integer "total", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_orders_on_number", unique: true
  end

  create_table "product_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "long_desc"
    t.string "name", null: false
    t.integer "price", default: 0, null: false
    t.string "short"
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.text "long_desc"
    t.string "name", null: false
    t.integer "price", default: 0, null: false
    t.string "short"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
  end

  create_table "set_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0
    t.integer "product_id", null: false
    t.integer "product_set_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_set_items_on_product_id"
    t.index ["product_set_id"], name: "index_set_items_on_product_set_id"
  end

  create_table "variant_attribute_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.integer "variant_attribute_id", null: false
    t.index ["variant_attribute_id"], name: "index_variant_attribute_values_on_variant_attribute_id"
  end

  create_table "variant_attributes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
  end

  create_table "variant_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "variant_attribute_value_id", null: false
    t.integer "variant_id", null: false
    t.index ["variant_attribute_value_id"], name: "index_variant_values_on_variant_attribute_value_id"
    t.index ["variant_id", "variant_attribute_value_id"], name: "idx_variant_values_unique", unique: true
    t.index ["variant_id"], name: "index_variant_values_on_variant_id"
  end

  create_table "variants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "position", default: 0
    t.integer "price", default: 0, null: false
    t.integer "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_variants_on_product_id"
  end

  add_foreign_key "campaign_items", "campaigns"
  add_foreign_key "collection_memberships", "collections"
  add_foreign_key "collection_memberships", "products"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "products", "categories"
  add_foreign_key "set_items", "product_sets"
  add_foreign_key "set_items", "products"
  add_foreign_key "variant_attribute_values", "variant_attributes"
  add_foreign_key "variant_values", "variant_attribute_values"
  add_foreign_key "variant_values", "variants"
  add_foreign_key "variants", "products"
end
