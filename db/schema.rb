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

ActiveRecord::Schema[8.1].define(version: 2026_07_17_165542) do
  create_table "account_users", force: :cascade do |t|
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "user_role", default: 0
    t.index ["account_id", "user_id"], name: "index_account_users_on_account_id_and_user_id", unique: true
  end

  create_table "accounts", force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.string "gocardless_access_token"
    t.integer "gocardless_mode", default: 0
    t.boolean "is_b2b", default: true, null: false
    t.boolean "is_b2c", default: false, null: false
    t.boolean "is_internal", default: false, null: false
    t.string "name"
    t.integer "owner_id"
    t.datetime "updated_at", null: false
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
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

  create_table "ahoy_events", force: :cascade do |t|
    t.string "name"
    t.text "properties"
    t.datetime "time"
    t.integer "user_id"
    t.integer "visit_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_messages", force: :cascade do |t|
    t.datetime "clicked_at"
    t.string "mailer"
    t.integer "newsletter_id", null: false
    t.datetime "opened_at"
    t.datetime "sent_at"
    t.text "subject"
    t.string "to"
    t.integer "user_id"
    t.string "user_type"
    t.index ["newsletter_id"], name: "index_ahoy_messages_on_newsletter_id"
    t.index ["to"], name: "index_ahoy_messages_on_to"
    t.index ["user_type", "user_id"], name: "index_ahoy_messages_on_user"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "app_version"
    t.string "browser"
    t.string "city"
    t.string "country"
    t.string "device_type"
    t.string "ip"
    t.text "landing_page"
    t.float "latitude"
    t.float "longitude"
    t.string "os"
    t.string "os_version"
    t.string "platform"
    t.text "referrer"
    t.string "referring_domain"
    t.string "region"
    t.datetime "started_at"
    t.text "user_agent"
    t.integer "user_id"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.text "audited_changes"
    t.string "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "audits1984_audits", force: :cascade do |t|
    t.integer "auditor_id", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.integer "session_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["auditor_id"], name: "index_audits1984_audits_on_auditor_id"
    t.index ["session_id"], name: "index_audits1984_audits_on_session_id"
  end

  create_table "console1984_commands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "sensitive_access_id"
    t.integer "session_id", null: false
    t.text "statements"
    t.datetime "updated_at", null: false
    t.index ["sensitive_access_id"], name: "index_console1984_commands_on_sensitive_access_id"
    t.index ["session_id", "created_at", "sensitive_access_id"], name: "on_session_and_sensitive_chronologically"
  end

  create_table "console1984_sensitive_accesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "justification"
    t.integer "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_console1984_sensitive_accesses_on_session_id"
  end

  create_table "console1984_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "reason"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_console1984_sessions_on_created_at"
    t.index ["user_id", "created_at"], name: "index_console1984_sessions_on_user_id_and_created_at"
  end

  create_table "console1984_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["username"], name: "index_console1984_users_on_username"
  end

  create_table "customers", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.integer "customer_account_id"
    t.datetime "deleted_at"
    t.string "email_address"
    t.datetime "gocardless_configured_at"
    t.string "gocardless_customer_id"
    t.string "gocardless_mandate_id"
    t.string "name"
    t.string "phone"
    t.datetime "subscribed_at"
    t.boolean "subscribed_to_newsletter", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["account_id"], name: "index_customers_on_account_id"
    t.index ["customer_account_id"], name: "index_customers_on_customer_account_id"
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "inventory_group_customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.integer "inventory_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_inventory_group_customers_on_customer_id"
    t.index ["inventory_group_id"], name: "index_inventory_group_customers_on_inventory_group_id"
  end

  create_table "inventory_group_suppliers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "inventory_group_id", null: false
    t.integer "supplier_id", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_group_id"], name: "index_inventory_group_suppliers_on_inventory_group_id"
    t.index ["supplier_id"], name: "index_inventory_group_suppliers_on_supplier_id"
  end

  create_table "inventory_groups", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_inventory_groups_on_account_id"
  end

  create_table "inventory_items", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.integer "inventory_group_id"
    t.integer "low_stock_threshold", default: 0, null: false
    t.string "name"
    t.integer "parent_id"
    t.integer "price_cents"
    t.string "price_currency"
    t.integer "unit_type", default: 0
    t.datetime "updated_at", null: false
    t.boolean "warn_when_low_on_stock", default: false, null: false
    t.string "weight_unit"
    t.decimal "weight_value", precision: 10, scale: 2
    t.index ["account_id"], name: "index_inventory_items_on_account_id"
    t.index ["deleted_at"], name: "index_inventory_items_on_deleted_at"
    t.index ["inventory_group_id"], name: "index_inventory_items_on_inventory_group_id"
    t.index ["parent_id"], name: "index_inventory_items_on_parent_id"
  end

  create_table "inventory_levels", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.integer "inventory_item_id", null: false
    t.integer "location_id", null: false
    t.integer "quantity", default: 0
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_inventory_levels_on_account_id"
    t.index ["inventory_item_id"], name: "index_inventory_levels_on_inventory_item_id"
    t.index ["location_id"], name: "index_inventory_levels_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.integer "account_id", null: false
    t.boolean "collection_point", default: false, null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_locations_on_account_id"
  end

  create_table "loyalty_cards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.string "identifier"
    t.integer "loyalty_program_id", null: false
    t.integer "points_balance", default: 0
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_loyalty_cards_on_customer_id"
    t.index ["identifier"], name: "index_loyalty_cards_on_identifier", unique: true
    t.index ["loyalty_program_id"], name: "index_loyalty_cards_on_loyalty_program_id"
  end

  create_table "loyalty_programs", force: :cascade do |t|
    t.integer "account_id", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.integer "currency_to_points_ratio", default: 1
    t.decimal "points_to_currency_ratio", precision: 10, scale: 2, default: "0.1"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_loyalty_programs_on_account_id"
  end

  create_table "loyalty_transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "loyalty_card_id", null: false
    t.integer "order_id"
    t.integer "transaction_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["loyalty_card_id"], name: "index_loyalty_transactions_on_loyalty_card_id"
    t.index ["order_id"], name: "index_loyalty_transactions_on_order_id"
  end

  create_table "newsletters", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "sent_at"
    t.string "subject"
    t.integer "target", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_newsletters_on_account_id"
  end

  create_table "notes", force: :cascade do |t|
    t.integer "account_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "notable_id", null: false
    t.string "notable_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["account_id"], name: "index_notes_on_account_id"
    t.index ["notable_type", "notable_id"], name: "index_notes_on_notable"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "GBP", null: false
    t.integer "inventory_item_id", null: false
    t.integer "location_id"
    t.integer "order_id", null: false
    t.integer "price_cents", default: 0, null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_item_id"], name: "index_order_items_on_inventory_item_id"
    t.index ["location_id"], name: "index_order_items_on_location_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "GBP", null: false
    t.integer "customer_id", null: false
    t.integer "location_id"
    t.integer "loyalty_discount_amount_cents", default: 0
    t.integer "loyalty_points_redeemed", default: 0
    t.text "notes"
    t.string "number"
    t.integer "status", default: 0, null: false
    t.integer "total_amount_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["account_id"], name: "index_orders_on_account_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["location_id"], name: "index_orders_on_location_id"
    t.index ["number"], name: "index_orders_on_number", unique: true
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "GBP", null: false
    t.integer "customer_id", null: false
    t.integer "order_id", null: false
    t.integer "payment_method", default: 0, null: false
    t.string "provider_reference"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_payments_on_account_id"
    t.index ["customer_id"], name: "index_payments_on_customer_id"
    t.index ["order_id"], name: "index_payments_on_order_id", unique: true
  end

  create_table "refer_referral_codes", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "referrals_count", default: 0
    t.integer "referrer_id", null: false
    t.string "referrer_type", null: false
    t.datetime "updated_at", null: false
    t.integer "visits_count", default: 0
    t.index ["code"], name: "index_refer_referral_codes_on_code", unique: true
    t.index ["referrer_type", "referrer_id"], name: "index_refer_referral_codes_on_referrer"
  end

  create_table "refer_referrals", force: :cascade do |t|
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", null: false
    t.integer "referee_id", null: false
    t.string "referee_type", null: false
    t.integer "referral_code_id"
    t.integer "referrer_id", null: false
    t.string "referrer_type", null: false
    t.datetime "updated_at", null: false
    t.index ["referee_type", "referee_id"], name: "index_refer_referrals_on_referee"
    t.index ["referral_code_id"], name: "index_refer_referrals_on_referral_code_id"
    t.index ["referrer_type", "referrer_id"], name: "index_refer_referrals_on_referrer"
  end

  create_table "refer_visits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip"
    t.integer "referral_code_id", null: false
    t.text "referrer"
    t.string "referring_domain"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.index ["referral_code_id"], name: "index_refer_visits_on_referral_code_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "supplier_prices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.integer "inventory_item_id", null: false
    t.integer "price_cents"
    t.integer "supplier_id", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_item_id"], name: "index_supplier_prices_on_inventory_item_id"
    t.index ["supplier_id"], name: "index_supplier_prices_on_supplier_id"
  end

  create_table "supplier_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "receiver_account_id", null: false
    t.integer "sender_account_id", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["receiver_account_id"], name: "index_supplier_requests_on_receiver_account_id"
    t.index ["sender_account_id"], name: "index_supplier_requests_on_sender_account_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email_address"
    t.string "name"
    t.string "phone"
    t.datetime "subscribed_at"
    t.boolean "subscribed_to_newsletter", default: false, null: false
    t.integer "supplier_account_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["account_id"], name: "index_suppliers_on_account_id"
    t.index ["deleted_at"], name: "index_suppliers_on_deleted_at"
    t.index ["supplier_account_id"], name: "index_suppliers_on_supplier_account_id"
    t.index ["user_id"], name: "index_suppliers_on_user_id"
  end

  create_table "support_request_comments", force: :cascade do |t|
    t.integer "account_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "support_request_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["account_id"], name: "index_support_request_comments_on_account_id"
    t.index ["support_request_id"], name: "index_support_request_comments_on_support_request_id"
    t.index ["user_id"], name: "index_support_request_comments_on_user_id"
  end

  create_table "support_requests", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.text "message"
    t.integer "requester_id", null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_support_requests_on_account_id"
    t.index ["requester_id"], name: "index_support_requests_on_requester_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "assigned_by_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date"
    t.integer "responsible_user_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_tasks_on_account_id"
    t.index ["assigned_by_id"], name: "index_tasks_on_assigned_by_id"
    t.index ["responsible_user_id"], name: "index_tasks_on_responsible_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email_address", null: false
    t.datetime "email_otp_sent_at"
    t.string "email_otp_token"
    t.string "name"
    t.boolean "onboarded", default: false, null: false
    t.boolean "otp_required_for_login", default: false, null: false
    t.string "otp_secret"
    t.string "password_digest", null: false
    t.boolean "prefers_email_login", default: false, null: false
    t.boolean "security_choice_made", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ahoy_messages", "newsletters"
  add_foreign_key "customers", "accounts"
  add_foreign_key "customers", "accounts", column: "customer_account_id"
  add_foreign_key "customers", "users"
  add_foreign_key "inventory_group_customers", "customers"
  add_foreign_key "inventory_group_customers", "inventory_groups"
  add_foreign_key "inventory_group_suppliers", "inventory_groups"
  add_foreign_key "inventory_group_suppliers", "suppliers"
  add_foreign_key "inventory_groups", "accounts"
  add_foreign_key "inventory_items", "accounts"
  add_foreign_key "inventory_items", "inventory_groups"
  add_foreign_key "inventory_items", "inventory_items", column: "parent_id"
  add_foreign_key "inventory_levels", "accounts"
  add_foreign_key "inventory_levels", "inventory_items"
  add_foreign_key "inventory_levels", "locations"
  add_foreign_key "locations", "accounts"
  add_foreign_key "loyalty_cards", "customers"
  add_foreign_key "loyalty_cards", "loyalty_programs"
  add_foreign_key "loyalty_programs", "accounts"
  add_foreign_key "loyalty_transactions", "loyalty_cards"
  add_foreign_key "loyalty_transactions", "orders"
  add_foreign_key "newsletters", "accounts"
  add_foreign_key "notes", "accounts"
  add_foreign_key "notes", "users"
  add_foreign_key "order_items", "inventory_items"
  add_foreign_key "order_items", "locations"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "accounts"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "locations"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "accounts"
  add_foreign_key "payments", "customers"
  add_foreign_key "payments", "orders"
  add_foreign_key "refer_visits", "refer_referral_codes", column: "referral_code_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "supplier_prices", "inventory_items"
  add_foreign_key "supplier_prices", "suppliers"
  add_foreign_key "supplier_requests", "accounts", column: "receiver_account_id"
  add_foreign_key "supplier_requests", "accounts", column: "sender_account_id"
  add_foreign_key "suppliers", "accounts"
  add_foreign_key "suppliers", "accounts", column: "supplier_account_id"
  add_foreign_key "suppliers", "users"
  add_foreign_key "support_request_comments", "accounts"
  add_foreign_key "support_request_comments", "support_requests"
  add_foreign_key "support_request_comments", "users"
  add_foreign_key "support_requests", "accounts"
  add_foreign_key "support_requests", "users", column: "requester_id"
  add_foreign_key "tasks", "accounts"
  add_foreign_key "tasks", "users", column: "assigned_by_id"
  add_foreign_key "tasks", "users", column: "responsible_user_id"
end
