# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20171011144654) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.integer  "activity_type",   null: false
    t.text     "payload_details", null: false
    t.string   "actor_name",      null: false
    t.datetime "activity_time",   null: false
    t.integer  "actor_id"
    t.string   "actor_type"
    t.integer  "company_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "activity_logs", ["actor_type", "actor_id"], name: "index_activity_logs_on_actor_type_and_actor_id", using: :btree
  add_index "activity_logs", ["company_id"], name: "index_activity_logs_on_company_id", using: :btree

  create_table "activity_logs_payloads_connectors", force: :cascade do |t|
    t.integer  "activity_log_id"
    t.integer  "payload_id"
    t.string   "payload_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "activity_logs_payloads_connectors", ["activity_log_id"], name: "index_activity_logs_payloads_connectors_on_activity_log_id", using: :btree
  add_index "activity_logs_payloads_connectors", ["payload_type", "payload_id"], name: "index_payload_connectors_on_payloads", using: :btree

  create_table "admins", force: :cascade do |t|
    t.string   "email",                            default: "",   null: false
    t.string   "encrypted_password",               default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                    default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "admin_birth_day"
    t.integer  "admin_birth_month"
    t.integer  "admin_birth_year"
    t.string   "admin_ssn"
    t.integer  "level"
    t.integer  "company_id"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "clock_type",                       default: 1,    null: false
    t.string   "locale",                 limit: 5, default: "fi", null: false
  end

  add_index "admins", ["company_id"], name: "index_admins_on_company_id", using: :btree
  add_index "admins", ["confirmation_token"], name: "index_admins_on_confirmation_token", unique: true, using: :btree
  add_index "admins", ["email"], name: "index_admins_on_email", unique: true, using: :btree
  add_index "admins", ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true, using: :btree

  create_table "api_secret_keys", force: :cascade do |t|
    t.string "name"
    t.string "key"
  end

  add_index "api_secret_keys", ["name"], name: "index_api_secret_keys_on_name", using: :btree

  create_table "coach_price_rates", force: :cascade do |t|
    t.integer  "coach_id"
    t.integer  "venue_id"
    t.integer  "sport_name",                         null: false
    t.datetime "start_time",                         null: false
    t.datetime "end_time",                           null: false
    t.decimal  "rate",       precision: 8, scale: 2
    t.string   "created_by"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "coach_price_rates", ["coach_id"], name: "index_coach_price_rates_on_coach_id", using: :btree
  add_index "coach_price_rates", ["venue_id"], name: "index_coach_price_rates_on_venue_id", using: :btree

  create_table "coach_salary_rates", force: :cascade do |t|
    t.integer  "coach_id"
    t.integer  "venue_id"
    t.integer  "sport_name",                                                    null: false
    t.decimal  "rate",                  precision: 8, scale: 2
    t.string   "created_by"
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.integer  "start_minute_of_a_day",                                         null: false
    t.integer  "end_minute_of_a_day",                                           null: false
    t.boolean  "monday",                                        default: false, null: false
    t.boolean  "tuesday",                                       default: false, null: false
    t.boolean  "wednesday",                                     default: false, null: false
    t.boolean  "thursday",                                      default: false, null: false
    t.boolean  "friday",                                        default: false, null: false
    t.boolean  "saturday",                                      default: false, null: false
    t.boolean  "sunday",                                        default: false, null: false
  end

  add_index "coach_salary_rates", ["coach_id"], name: "index_coach_salary_rates_on_coach_id", using: :btree
  add_index "coach_salary_rates", ["venue_id"], name: "index_coach_salary_rates_on_venue_id", using: :btree

  create_table "coaches", force: :cascade do |t|
    t.string   "email",                  default: "",   null: false
    t.string   "encrypted_password",     default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone_number"
    t.string   "address"
    t.string   "image"
    t.string   "experience"
    t.text     "description"
    t.string   "stripe_id"
    t.string   "locale",                 default: "en", null: false
    t.integer  "clock_type",             default: 1,    null: false
    t.integer  "level",                  default: 0,    null: false
    t.integer  "company_id"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "sports"
  end

  add_index "coaches", ["company_id"], name: "index_coaches_on_company_id", using: :btree
  add_index "coaches", ["email"], name: "index_coaches_on_email", unique: true, using: :btree
  add_index "coaches", ["reset_password_token"], name: "index_coaches_on_reset_password_token", unique: true, using: :btree

  create_table "companies", force: :cascade do |t|
    t.string   "company_legal_name"
    t.string   "company_country"
    t.string   "company_business_type"
    t.string   "company_tax_id"
    t.string   "company_street_address"
    t.string   "company_zip"
    t.string   "company_city"
    t.string   "company_website"
    t.string   "company_phone"
    t.datetime "created_at",                                                         null: false
    t.datetime "updated_at",                                                         null: false
    t.string   "company_iban"
    t.string   "stripe_user_id"
    t.string   "publishable_key"
    t.string   "secret_key"
    t.string   "currency"
    t.string   "stripe_account_type"
    t.string   "stripe_account_status",                               default: "{}"
    t.string   "company_bic"
    t.string   "invoice_sender_email"
    t.string   "bank_name"
    t.string   "cached_invoice_period_end"
    t.string   "cached_invoice_period_start"
    t.integer  "country_id",                                          default: 1,    null: false
    t.string   "usa_state"
    t.string   "usa_routing_number"
    t.decimal  "tax_rate",                    precision: 5, scale: 4, default: 0.0,  null: false
    t.string   "copy_booking_mail_to"
    t.string   "coupon_code"
  end

  create_table "company_notes", force: :cascade do |t|
    t.integer  "company_id"
    t.text     "text",                default: "", null: false
    t.integer  "last_edited_by_id"
    t.string   "last_edited_by_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "company_notes", ["company_id"], name: "index_company_notes_on_company_id", using: :btree
  add_index "company_notes", ["last_edited_by_type", "last_edited_by_id"], name: "index_company_notes_on_last_edited_by_type_polymorphic", using: :btree

  create_table "coupons", force: :cascade do |t|
    t.string   "code",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  create_table "court_connectors", force: :cascade do |t|
    t.integer  "court_id"
    t.integer  "shared_court_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "court_connectors", ["court_id"], name: "index_court_connectors_on_court_id", using: :btree
  add_index "court_connectors", ["shared_court_id"], name: "index_court_connectors_on_shared_court_id", using: :btree

  create_table "courts", force: :cascade do |t|
    t.text     "court_description"
    t.integer  "venue_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "duration_policy"
    t.integer  "start_time_policy"
    t.boolean  "active",            default: false, null: false
    t.boolean  "indoor",            default: false, null: false
    t.integer  "index"
    t.integer  "sport_name"
    t.boolean  "payment_skippable", default: false, null: false
    t.integer  "surface"
    t.string   "custom_name"
    t.boolean  "private",           default: false, null: false
  end

  add_index "courts", ["venue_id"], name: "index_courts_on_venue_id", using: :btree

  create_table "courts_holidays", force: :cascade do |t|
    t.integer "holiday_id"
    t.integer "court_id"
  end

  add_index "courts_holidays", ["court_id"], name: "index_courts_holidays_on_court_id", using: :btree
  add_index "courts_holidays", ["holiday_id"], name: "index_courts_holidays_on_holiday_id", using: :btree

  create_table "credits", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "company_id"
    t.integer  "creditable_id"
    t.string   "creditable_type"
    t.decimal  "balance",         precision: 8, scale: 2
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "credits", ["company_id"], name: "index_credits_on_company_id", using: :btree
  add_index "credits", ["creditable_type", "creditable_id"], name: "index_credits_on_creditable_type_and_creditable_id", using: :btree
  add_index "credits", ["user_id"], name: "index_credits_on_user_id", using: :btree

  create_table "custom_invoice_components", force: :cascade do |t|
    t.integer  "invoice_id"
    t.decimal  "price",       precision: 8, scale: 2
    t.boolean  "is_billed",                           default: false, null: false
    t.boolean  "is_paid",                             default: false, null: false
    t.string   "name"
    t.decimal  "vat_decimal", precision: 6, scale: 5
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
  end

  add_index "custom_invoice_components", ["invoice_id"], name: "index_custom_invoice_components_on_invoice_id", using: :btree

  create_table "custom_mail_email_list_connectors", force: :cascade do |t|
    t.integer  "custom_mail_id"
    t.integer  "email_list_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "custom_mail_email_list_connectors", ["custom_mail_id"], name: "index_custom_mail_email_list_connectors_on_custom_mail_id", using: :btree
  add_index "custom_mail_email_list_connectors", ["email_list_id"], name: "index_custom_mail_email_list_connectors_on_email_list_id", using: :btree

  create_table "custom_mails", force: :cascade do |t|
    t.text     "recipient_users"
    t.string   "from"
    t.string   "subject"
    t.text     "body"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "venue_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "custom_mails", ["venue_id"], name: "index_custom_mails_on_venue_id", using: :btree

  create_table "day_offs", force: :cascade do |t|
    t.integer  "place_id"
    t.string   "place_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "start_time"
    t.datetime "end_time"
  end

  add_index "day_offs", ["place_type", "place_id"], name: "index_day_offs_on_place_type_and_place_id", using: :btree

  create_table "devices", force: :cascade do |t|
    t.string   "token"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "devices", ["user_id"], name: "index_devices_on_user_id", using: :btree

  create_table "discount_connections", force: :cascade do |t|
    t.integer  "discount_id"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "discount_connections", ["discount_id"], name: "index_discount_connections_on_discount_id", using: :btree
  add_index "discount_connections", ["user_id"], name: "index_discount_connections_on_user_id", using: :btree

  create_table "discounts", force: :cascade do |t|
    t.string   "name"
    t.float    "value",                            null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "venue_id"
    t.integer  "method"
    t.boolean  "round",            default: false, null: false
    t.integer  "court_type",       default: 0
    t.date     "start_date"
    t.date     "end_date"
    t.text     "time_limitations"
    t.string   "court_sports"
    t.string   "court_surfaces"
  end

  add_index "discounts", ["venue_id"], name: "index_discounts_on_venue_id", using: :btree

  create_table "dividers", force: :cascade do |t|
    t.integer  "price_id"
    t.integer  "court_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "dividers", ["court_id"], name: "index_dividers_on_court_id", using: :btree
  add_index "dividers", ["price_id"], name: "index_dividers_on_price_id", using: :btree

  create_table "email_list_user_connectors", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "email_list_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "email_list_user_connectors", ["email_list_id"], name: "index_email_list_user_connectors_on_email_list_id", using: :btree
  add_index "email_list_user_connectors", ["user_id"], name: "index_email_list_user_connectors_on_user_id", using: :btree

  create_table "email_lists", force: :cascade do |t|
    t.string   "name"
    t.integer  "venue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "email_lists", ["venue_id"], name: "index_email_lists_on_venue_id", using: :btree

  create_table "favourite_venues", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "venue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "favourite_venues", ["user_id"], name: "index_favourite_venues_on_user_id", using: :btree
  add_index "favourite_venues", ["venue_id"], name: "index_favourite_venues_on_venue_id", using: :btree

  create_table "game_pass_coach_connections", force: :cascade do |t|
    t.integer  "game_pass_id", null: false
    t.integer  "coach_id",     null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "game_pass_coach_connections", ["coach_id"], name: "index_game_pass_coach_connections_on_coach_id", using: :btree
  add_index "game_pass_coach_connections", ["game_pass_id"], name: "index_game_pass_coach_connections_on_game_pass_id", using: :btree

  create_table "game_passes", force: :cascade do |t|
    t.decimal  "total_charges",     precision: 8, scale: 3
    t.decimal  "remaining_charges", precision: 8, scale: 3
    t.decimal  "price"
    t.boolean  "active",                                    default: false, null: false
    t.integer  "user_id"
    t.integer  "venue_id"
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.boolean  "is_paid",                                   default: false, null: false
    t.string   "template_name"
    t.string   "court_sports"
    t.integer  "court_type",                                default: 0
    t.text     "time_limitations"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "name"
    t.integer  "billing_phase",                             default: 0
    t.string   "court_surfaces"
  end

  add_index "game_passes", ["user_id"], name: "index_game_passes_on_user_id", using: :btree
  add_index "game_passes", ["venue_id"], name: "index_game_passes_on_venue_id", using: :btree

  create_table "gamepass_invoice_components", force: :cascade do |t|
    t.integer  "invoice_id"
    t.integer  "game_pass_id"
    t.decimal  "price",        precision: 8, scale: 2
    t.boolean  "is_billed",                            default: false, null: false
    t.boolean  "is_paid",                              default: false, null: false
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
  end

  add_index "gamepass_invoice_components", ["game_pass_id"], name: "index_gamepass_invoice_components_on_game_pass_id", using: :btree
  add_index "gamepass_invoice_components", ["invoice_id"], name: "index_gamepass_invoice_components_on_invoice_id", using: :btree

  create_table "group_classifications", force: :cascade do |t|
    t.integer  "venue_id"
    t.string   "name"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.decimal  "price"
    t.integer  "price_policy", default: 0, null: false
  end

  add_index "group_classifications", ["venue_id"], name: "index_group_classifications_on_venue_id", using: :btree

  create_table "group_classifications_connectors", force: :cascade do |t|
    t.integer "group_classification_id"
    t.integer "group_id"
  end

  add_index "group_classifications_connectors", ["group_classification_id"], name: "index_groups_classifications_on_classification_id", using: :btree
  add_index "group_classifications_connectors", ["group_id"], name: "index_groups_classifications_on_group_id", using: :btree

  create_table "group_coach_connections", force: :cascade do |t|
    t.integer  "group_id",   null: false
    t.integer  "coach_id",   null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "group_coach_connections", ["coach_id"], name: "index_group_coach_connections_on_coach_id", using: :btree
  add_index "group_coach_connections", ["group_id"], name: "index_group_coach_connections_on_group_id", using: :btree

  create_table "group_custom_billers", force: :cascade do |t|
    t.string   "company_legal_name"
    t.string   "company_business_type"
    t.string   "company_tax_id"
    t.string   "bank_name"
    t.string   "company_iban"
    t.string   "company_bic"
    t.string   "company_country"
    t.string   "company_street_address"
    t.string   "company_zip"
    t.string   "company_city"
    t.string   "company_phone"
    t.string   "company_website"
    t.string   "invoice_sender_email"
    t.decimal  "tax_rate",               precision: 5, scale: 4, default: 0.0, null: false
    t.integer  "country_id",                                     default: 1,   null: false
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
  end

  create_table "group_members", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "group_members", ["group_id"], name: "index_group_members_on_group_id", using: :btree
  add_index "group_members", ["user_id"], name: "index_group_members_on_user_id", using: :btree

  create_table "group_seasons", force: :cascade do |t|
    t.integer  "group_id"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "current",                                     default: false, null: false
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.decimal  "participation_price", precision: 8, scale: 2
  end

  add_index "group_seasons", ["group_id"], name: "index_group_seasons_on_group_id", using: :btree

  create_table "group_subscription_invoice_components", force: :cascade do |t|
    t.integer  "invoice_id"
    t.integer  "group_subscription_id"
    t.decimal  "price",                 precision: 8, scale: 2
    t.boolean  "is_billed",                                     default: false, null: false
    t.boolean  "is_paid",                                       default: false, null: false
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
  end

  add_index "group_subscription_invoice_components", ["group_subscription_id"], name: "index_invoice_components_on_group_subscription_id", using: :btree
  add_index "group_subscription_invoice_components", ["invoice_id"], name: "index_group_subscription_invoice_components_on_invoice_id", using: :btree

  create_table "group_subscriptions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "group_season_id"
    t.decimal  "price",           precision: 8, scale: 2
    t.integer  "billing_phase",                           default: 0
    t.boolean  "is_paid",                                 default: false, null: false
    t.boolean  "cancelled",                               default: false, null: false
    t.boolean  "refunded",                                default: false, null: false
    t.string   "charge_id"
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.decimal  "amount_paid",     precision: 8, scale: 2
  end

  add_index "group_subscriptions", ["group_season_id"], name: "index_group_subscriptions_on_group_season_id", using: :btree
  add_index "group_subscriptions", ["user_id"], name: "index_group_subscriptions_on_user_id", using: :btree

  create_table "groups", force: :cascade do |t|
    t.integer  "venue_id"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "classification_id"
    t.integer  "coach_id"
    t.string   "name"
    t.text     "description"
    t.integer  "max_participants"
    t.text     "skill_levels"
    t.decimal  "participation_price", precision: 8, scale: 2
    t.integer  "priced_duration",                             default: 0
    t.integer  "cancellation_policy",                         default: 0
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.integer  "custom_biller_id"
  end

  add_index "groups", ["custom_biller_id"], name: "index_groups_on_custom_biller_id", using: :btree
  add_index "groups", ["owner_type", "owner_id"], name: "index_groups_on_owner_type_and_owner_id", using: :btree
  add_index "groups", ["venue_id"], name: "index_groups_on_venue_id", using: :btree

  create_table "guests", force: :cascade do |t|
    t.string   "full_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "holidays", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoice_components", force: :cascade do |t|
    t.integer  "reservation_id"
    t.boolean  "is_paid",                                default: false, null: false
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.boolean  "is_billed",                              default: false, null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal  "price",          precision: 8, scale: 2
    t.integer  "invoice_id"
  end

  add_index "invoice_components", ["invoice_id"], name: "index_invoice_components_on_invoice_id", using: :btree
  add_index "invoice_components", ["reservation_id"], name: "index_invoice_components_on_reservation_id", using: :btree

  create_table "invoices", force: :cascade do |t|
    t.integer  "company_id"
    t.boolean  "is_draft",                                       default: true,  null: false
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.decimal  "total",                  precision: 8, scale: 2
    t.integer  "owner_id",                                                       null: false
    t.boolean  "is_paid",                                        default: false, null: false
    t.string   "reference_number"
    t.datetime "billing_time"
    t.datetime "due_time"
    t.integer  "group_custom_biller_id"
    t.string   "owner_type"
  end

  add_index "invoices", ["company_id"], name: "index_invoices_on_company_id", using: :btree
  add_index "invoices", ["group_custom_biller_id"], name: "index_invoices_on_group_custom_biller_id", using: :btree
  add_index "invoices", ["owner_id", "owner_type"], name: "index_invoices_on_owner_id_and_owner_type", using: :btree

  create_table "membership_coach_connections", force: :cascade do |t|
    t.integer  "coach_id"
    t.integer  "membership_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "membership_coach_connections", ["coach_id"], name: "index_membership_coach_connections_on_coach_id", using: :btree
  add_index "membership_coach_connections", ["membership_id"], name: "index_membership_coach_connections_on_membership_id", using: :btree

  create_table "membership_connectors", force: :cascade do |t|
    t.integer  "membership_id"
    t.integer  "reservation_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "membership_connectors", ["membership_id"], name: "index_membership_connectors_on_membership_id", using: :btree
  add_index "membership_connectors", ["reservation_id"], name: "index_membership_connectors_on_reservation_id", using: :btree

  create_table "memberships", force: :cascade do |t|
    t.datetime "end_time"
    t.datetime "start_time"
    t.integer  "user_id"
    t.integer  "venue_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.float    "price"
    t.boolean  "invoice_by_cc",   default: false, null: false
    t.string   "subscription_id"
    t.string   "title"
    t.text     "note"
    t.string   "user_type"
  end

  add_index "memberships", ["user_id", "user_type"], name: "index_memberships_on_user_id_and_user_type", using: :btree

  create_table "participation_credits", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "company_id"
    t.integer  "group_classification_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "participation_credits", ["company_id"], name: "index_participation_credits_on_company_id", using: :btree
  add_index "participation_credits", ["group_classification_id"], name: "index_participation_credits_on_group_classification_id", using: :btree
  add_index "participation_credits", ["user_id"], name: "index_participation_credits_on_user_id", using: :btree

  create_table "participation_invoice_components", force: :cascade do |t|
    t.integer  "invoice_id"
    t.integer  "participation_id"
    t.decimal  "price",            precision: 8, scale: 2
    t.boolean  "is_billed",                                default: false, null: false
    t.boolean  "is_paid",                                  default: false, null: false
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
  end

  add_index "participation_invoice_components", ["invoice_id"], name: "index_participation_invoice_components_on_invoice_id", using: :btree
  add_index "participation_invoice_components", ["participation_id"], name: "index_participation_invoice_components_on_participation_id", using: :btree

  create_table "participations", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "reservation_id"
    t.decimal  "price",          precision: 8, scale: 2
    t.integer  "billing_phase",                          default: 0
    t.boolean  "is_paid",                                default: false, null: false
    t.boolean  "cancelled",                              default: false, null: false
    t.boolean  "refunded",                               default: false, null: false
    t.string   "charge_id"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  add_index "participations", ["reservation_id"], name: "index_participations_on_reservation_id", using: :btree
  add_index "participations", ["user_id"], name: "index_participations_on_user_id", using: :btree

  create_table "photos", force: :cascade do |t|
    t.integer  "venue_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  add_index "photos", ["venue_id"], name: "index_photos_on_venue_id", using: :btree

  create_table "prices", force: :cascade do |t|
    t.float    "price"
    t.integer  "court_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "day_of_week"
    t.boolean  "monday"
    t.boolean  "tuesday"
    t.boolean  "wednesday"
    t.boolean  "thursday"
    t.boolean  "friday"
    t.boolean  "saturday"
    t.boolean  "sunday"
    t.integer  "start_minute_of_a_day"
    t.integer  "end_minute_of_a_day"
  end

  add_index "prices", ["court_id"], name: "index_prices_on_court_id", using: :btree

  create_table "reservation_coach_connections", force: :cascade do |t|
    t.integer  "reservation_id",                                         null: false
    t.integer  "coach_id",                                               null: false
    t.decimal  "salary",         precision: 8, scale: 2
    t.boolean  "salary_paid",                            default: false, null: false
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  add_index "reservation_coach_connections", ["coach_id"], name: "index_reservation_coach_connections_on_coach_id", using: :btree
  add_index "reservation_coach_connections", ["reservation_id"], name: "index_reservation_coach_connections_on_reservation_id", using: :btree

  create_table "reservation_participant_connections", force: :cascade do |t|
    t.integer "user_id",                      null: false
    t.integer "reservation_id",               null: false
    t.decimal "price",          default: 0.0, null: false
    t.decimal "amount_paid",    default: 0.0, null: false
  end

  add_index "reservation_participant_connections", ["reservation_id"], name: "index_reservation_participant_connections_on_reservation_id", using: :btree
  add_index "reservation_participant_connections", ["user_id"], name: "index_reservation_participant_connections_on_user_id", using: :btree

  create_table "reservations", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "date"
    t.decimal  "price"
    t.decimal  "total"
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.integer  "court_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.boolean  "is_paid",                                       default: false, null: false
    t.string   "user_type"
    t.string   "charge_id"
    t.boolean  "refunded",                                      default: false, null: false
    t.integer  "payment_type"
    t.integer  "booking_type"
    t.decimal  "amount_paid",                                   default: 0.0
    t.text     "note"
    t.integer  "initial_membership_id"
    t.boolean  "reselling",                                     default: false, null: false
    t.boolean  "inactive",                                      default: false, null: false
    t.integer  "billing_phase",                                 default: 0
    t.integer  "game_pass_id"
    t.integer  "participations_count",                          default: 0
    t.integer  "coach_id"
    t.decimal  "coach_salary",          precision: 8, scale: 2
    t.boolean  "coach_salary_paid",                             default: false, null: false
    t.integer  "classification_id"
  end

  add_index "reservations", ["coach_id"], name: "index_reservations_on_coach_id", using: :btree
  add_index "reservations", ["game_pass_id"], name: "index_reservations_on_game_pass_id", using: :btree
  add_index "reservations", ["user_id", "user_type"], name: "index_reservations_on_user_id_and_user_type", using: :btree
  add_index "reservations", ["user_id"], name: "index_reservations_on_user_id", using: :btree

  create_table "reservations_logs", force: :cascade do |t|
    t.integer  "reservation_id"
    t.integer  "status"
    t.text     "params"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "reservations_logs", ["reservation_id"], name: "index_reservations_logs_on_reservation_id", using: :btree

  create_table "reviews", force: :cascade do |t|
    t.text     "text"
    t.float    "rating",     null: false
    t.integer  "author_id"
    t.integer  "venue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "reviews", ["author_id"], name: "index_reviews_on_author_id", using: :btree
  add_index "reviews", ["venue_id"], name: "index_reviews_on_venue_id", using: :btree

  create_table "saved_invoice_user_connections", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "company_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "connection_type", default: 0
  end

  add_index "saved_invoice_user_connections", ["company_id"], name: "index_saved_invoice_user_connections_on_company_id", using: :btree
  add_index "saved_invoice_user_connections", ["user_id"], name: "index_saved_invoice_user_connections_on_user_id", using: :btree

  create_table "settings", force: :cascade do |t|
    t.integer  "owner_id",   null: false
    t.string   "owner_type", null: false
    t.string   "name",       null: false
    t.string   "value",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "settings", ["name"], name: "index_settings_on_name", using: :btree
  add_index "settings", ["owner_type", "owner_id"], name: "index_settings_on_owner_type_and_owner_id", using: :btree

  create_table "user_permissions", force: :cascade do |t|
    t.integer  "owner_id",   null: false
    t.string   "owner_type", null: false
    t.string   "permission", null: false
    t.string   "value",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_permissions", ["owner_type", "owner_id"], name: "index_user_permissions_on_owner_type_and_owner_id", using: :btree

  create_table "user_social_accounts", force: :cascade do |t|
    t.integer "user_id"
    t.string  "provider"
    t.string  "uid"
  end

  add_index "user_social_accounts", ["uid", "provider"], name: "index_user_social_accounts_on_uid_and_provider", using: :btree
  add_index "user_social_accounts", ["user_id"], name: "index_user_social_accounts_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                   default: "",   null: false
    t.string   "encrypted_password",      default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "first_name"
    t.string   "last_name"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "image"
    t.string   "phone_number"
    t.string   "stripe_id"
    t.string   "street_address"
    t.string   "zipcode"
    t.string   "city"
    t.float    "outstanding_balance"
    t.string   "locale",                  default: "en", null: false
    t.decimal  "longitude"
    t.decimal  "latitude"
    t.string   "current_city"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "default_country_id"
    t.integer  "clock_type",              default: 1,    null: false
    t.float    "skill_level"
    t.string   "additional_phone_number"
    t.text     "note"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "venue_user_connectors", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "venue_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.boolean  "email_subscription", default: true, null: false
  end

  add_index "venue_user_connectors", ["user_id"], name: "index_venue_user_connectors_on_user_id", using: :btree
  add_index "venue_user_connectors", ["venue_id"], name: "index_venue_user_connectors_on_venue_id", using: :btree

  create_table "venues", force: :cascade do |t|
    t.string   "venue_name"
    t.float    "latitude"
    t.float    "longitude"
    t.text     "description"
    t.text     "parking_info"
    t.text     "transit_info"
    t.string   "website"
    t.string   "phone_number"
    t.integer  "company_id"
    t.datetime "created_at",                                                                            null: false
    t.datetime "updated_at",                                                                            null: false
    t.string   "street"
    t.string   "city"
    t.string   "zip"
    t.integer  "booking_ahead_limit",                                       default: 365
    t.text     "business_hours"
    t.integer  "primary_photo_id"
    t.text     "court_counts"
    t.text     "confirmation_message"
    t.integer  "cancellation_time",                                         default: 24,                null: false
    t.text     "registration_confirmation_message"
    t.text     "custom_colors"
    t.decimal  "invoice_fee",                       precision: 8, scale: 2
    t.integer  "connected_venue_id"
    t.boolean  "allow_overlapping_resell",                                  default: false,             null: false
    t.integer  "status",                                                    default: 0,                 null: false
    t.integer  "country_id",                                                default: 1,                 null: false
    t.text     "user_colors"
    t.text     "discount_colors"
    t.string   "timezone",                                                  default: "Europe/Helsinki", null: false
    t.integer  "max_consecutive_bookable_hours"
    t.integer  "max_bookable_hours_per_day"
    t.text     "classification_colors"
    t.text     "group_colors"
    t.text     "coach_colors"
  end

  add_index "venues", ["company_id"], name: "index_venues_on_company_id", using: :btree
  add_index "venues", ["connected_venue_id"], name: "index_venues_on_connected_venue_id", using: :btree

  add_foreign_key "activity_logs", "companies"
  add_foreign_key "admins", "companies"
  add_foreign_key "coach_price_rates", "coaches"
  add_foreign_key "coach_price_rates", "venues"
  add_foreign_key "coach_salary_rates", "coaches"
  add_foreign_key "coach_salary_rates", "venues"
  add_foreign_key "coaches", "companies"
  add_foreign_key "court_connectors", "courts"
  add_foreign_key "courts", "venues"
  add_foreign_key "courts_holidays", "courts"
  add_foreign_key "courts_holidays", "holidays"
  add_foreign_key "credits", "companies"
  add_foreign_key "credits", "users"
  add_foreign_key "custom_invoice_components", "invoices"
  add_foreign_key "custom_mail_email_list_connectors", "custom_mails"
  add_foreign_key "custom_mail_email_list_connectors", "email_lists"
  add_foreign_key "custom_mails", "venues"
  add_foreign_key "devices", "users"
  add_foreign_key "discount_connections", "discounts"
  add_foreign_key "discount_connections", "users"
  add_foreign_key "discounts", "venues"
  add_foreign_key "dividers", "courts"
  add_foreign_key "dividers", "prices"
  add_foreign_key "email_list_user_connectors", "email_lists"
  add_foreign_key "email_list_user_connectors", "users"
  add_foreign_key "email_lists", "venues"
  add_foreign_key "favourite_venues", "users"
  add_foreign_key "favourite_venues", "venues"
  add_foreign_key "game_passes", "users"
  add_foreign_key "game_passes", "venues"
  add_foreign_key "gamepass_invoice_components", "game_passes"
  add_foreign_key "gamepass_invoice_components", "invoices"
  add_foreign_key "group_classifications", "venues"
  add_foreign_key "group_classifications_connectors", "group_classifications"
  add_foreign_key "group_classifications_connectors", "groups"
  add_foreign_key "group_members", "groups"
  add_foreign_key "group_members", "users"
  add_foreign_key "group_seasons", "groups"
  add_foreign_key "group_subscription_invoice_components", "group_subscriptions"
  add_foreign_key "group_subscription_invoice_components", "invoices"
  add_foreign_key "group_subscriptions", "group_seasons"
  add_foreign_key "group_subscriptions", "users"
  add_foreign_key "groups", "venues"
  add_foreign_key "invoice_components", "invoices"
  add_foreign_key "invoice_components", "reservations"
  add_foreign_key "invoices", "companies"
  add_foreign_key "membership_coach_connections", "coaches"
  add_foreign_key "membership_coach_connections", "memberships"
  add_foreign_key "membership_connectors", "memberships"
  add_foreign_key "membership_connectors", "reservations"
  add_foreign_key "participation_credits", "companies"
  add_foreign_key "participation_credits", "group_classifications"
  add_foreign_key "participation_credits", "users"
  add_foreign_key "participation_invoice_components", "invoices"
  add_foreign_key "participation_invoice_components", "participations"
  add_foreign_key "participations", "reservations"
  add_foreign_key "participations", "users"
  add_foreign_key "photos", "venues"
  add_foreign_key "prices", "courts"
  add_foreign_key "reservation_participant_connections", "reservations"
  add_foreign_key "reservation_participant_connections", "users"
  add_foreign_key "reservations", "group_classifications", column: "classification_id"
  add_foreign_key "reservations_logs", "reservations"
  add_foreign_key "reviews", "venues"
  add_foreign_key "saved_invoice_user_connections", "companies"
  add_foreign_key "saved_invoice_user_connections", "users"
  add_foreign_key "venue_user_connectors", "users"
  add_foreign_key "venue_user_connectors", "venues"
  add_foreign_key "venues", "companies"
end
