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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "activities", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "user_id"
    t.string   "category"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "delta",       :limit => 1, :default => 1
    t.integer  "system_id",   :limit => 1
  end

  add_index "activities", ["system_id"], :name => "system_id"

  create_table "ad_clicks", :force => true do |t|
    t.integer  "ad_id"
    t.integer  "user_id"
    t.string   "ip",         :limit => 20
    t.datetime "created_at"
    t.string   "referrer",   :limit => 200
  end

  create_table "ad_units", :force => true do |t|
    t.string   "name",         :limit => 200
    t.integer  "height"
    t.integer  "width"
    t.string   "content_type", :limit => 20
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "system_id"
  end

  create_table "ad_zones", :force => true do |t|
    t.string   "name",                    :limit => 200
    t.text     "description"
    t.integer  "ad_unit_id"
    t.string   "period",                  :limit => 20
    t.integer  "minimum_period_quantity"
    t.float    "price_per_period"
    t.integer  "concurrency_limit"
    t.string   "url_pattern",             :limit => 200
    t.integer  "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "system_id"
    t.integer  "impression_count",                       :default => 0
    t.datetime "impressions_from"
  end

  create_table "ad_zones_ads", :force => true do |t|
    t.integer "ad_id",      :default => 0, :null => false
    t.integer "ad_zone_id", :default => 0, :null => false
  end

  create_table "ads", :force => true do |t|
    t.integer  "system_id",                                           :null => false
    t.text     "body"
    t.integer  "user_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "impression_count",                     :default => 0
    t.float    "price_paid"
    t.datetime "paid_at"
    t.string   "creative_file_name",    :limit => 200
    t.integer  "creative_file_size"
    t.string   "creative_content_type", :limit => 50
    t.datetime "updated_at"
    t.string   "name",                  :limit => 200
    t.text     "notes"
    t.datetime "activated"
    t.string   "link",                  :limit => 200
    t.integer  "allow_html",            :limit => 1,   :default => 0
    t.integer  "is_house_ad",           :limit => 1,   :default => 0
    t.integer  "weighting",                            :default => 5
    t.integer  "height"
    t.integer  "width"
    t.integer  "approved_by_id"
  end

  create_table "assets", :force => true do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "tags"
    t.integer  "height"
    t.integer  "width"
    t.string   "extension",         :limit => 10
    t.string   "code",              :limit => 64
    t.integer  "is_image"
    t.integer  "system_id",         :limit => 1
  end

  add_index "assets", ["system_id"], :name => "system_id"

  create_table "block_instances", :force => true do |t|
    t.integer  "page_id"
    t.integer  "block_id"
    t.string   "field_name"
    t.text     "field_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "instance_id", :limit => 200
    t.integer  "version",                    :default => 0
    t.integer  "system_id",   :limit => 1
  end

  add_index "block_instances", ["page_id", "instance_id"], :name => "page_id"
  add_index "block_instances", ["system_id"], :name => "system_id"

  create_table "blocks", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "show_editors",  :limit => 1, :default => 1
    t.integer  "system_id",     :limit => 1
    t.integer  "all_templates", :limit => 1, :default => 0
    t.integer  "user_id"
  end

  add_index "blocks", ["system_id"], :name => "system_id"

  create_table "blocks_page_templates", :id => false, :force => true do |t|
    t.integer "page_template_id"
    t.integer "block_id"
  end

  create_table "calendar_entries", :force => true do |t|
    t.integer  "calendar_id"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "name",                   :limit => 200
    t.text     "description"
    t.integer  "user_id"
    t.integer  "location_id"
    t.integer  "calendar_entry_type_id"
    t.string   "image_file_name",        :limit => 200
    t.time     "start_time"
    t.time     "end_time"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "approved_at"
    t.string   "telephone",              :limit => 100, :default => ""
    t.string   "email",                  :limit => 100, :default => ""
    t.string   "website",                :limit => 200, :default => ""
    t.integer  "system_id",              :limit => 1
    t.integer  "sell_tickets",           :limit => 1,   :default => 0
    t.integer  "tickets_remaining",                     :default => 0
    t.float    "ticket_price"
    t.integer  "seller_id"
    t.float    "tax_rate",                              :default => 0.0
    t.string   "contact",                :limit => 100
  end

  add_index "calendar_entries", ["system_id"], :name => "system_id"

  create_table "calendar_entry_types", :force => true do |t|
    t.integer  "calendar_id"
    t.string   "name",        :limit => 200
    t.text     "description"
    t.datetime "updated_at"
    t.integer  "system_id",   :limit => 1
  end

  add_index "calendar_entry_types", ["system_id"], :name => "system_id"

  create_table "calendars", :force => true do |t|
    t.string   "name",        :limit => 200
    t.text     "description"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url",         :limit => 200
    t.integer  "system_id",   :limit => 1
  end

  add_index "calendars", ["system_id"], :name => "system_id"

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "is_visible",                    :default => 1
    t.text     "path"
    t.integer  "is_readable_anon", :limit => 1
    t.integer  "system_id",        :limit => 1
  end

  add_index "categories", ["system_id"], :name => "system_id"

  create_table "category_groups", :force => true do |t|
    t.integer  "category_id"
    t.integer  "group_id"
    t.datetime "updated_at"
    t.integer  "can_read",    :limit => 1
    t.integer  "can_write",   :limit => 1
  end

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "is_moderated", :limit => 1,   :default => 0
    t.integer  "is_visible",   :limit => 1,   :default => 0
    t.text     "body"
    t.string   "user_name",    :limit => 200
    t.string   "user_email",   :limit => 200
    t.string   "user_url",     :limit => 200
    t.string   "url",          :limit => 200
    t.integer  "system_id"
  end

  add_index "comments", ["url"], :name => "url"

  create_table "conversation_users", :force => true do |t|
    t.integer  "user_id"
    t.datetime "updated_at"
    t.integer  "conversation_id"
  end

  create_table "conversations", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "is_public"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "system_id",  :limit => 1
  end

  add_index "conversations", ["system_id"], :name => "system_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "design_histories", :force => true do |t|
    t.string   "model",      :limit => 20
    t.integer  "model_id"
    t.text     "header"
    t.text     "footer"
    t.text     "body"
    t.integer  "user_id"
    t.datetime "updated_at"
    t.integer  "system_id"
  end

  create_table "events", :force => true do |t|
    t.string   "ip_address"
    t.string   "url"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       :limit => 200
    t.string   "reference",  :limit => 100
    t.integer  "user_id"
  end

  create_table "experiments", :force => true do |t|
    t.string   "name",                :limit => 200
    t.integer  "user_id"
    t.integer  "system_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url1",                :limit => 250
    t.string   "url2",                :limit => 250
    t.integer  "percentage_visitors"
    t.text     "notes"
    t.integer  "goal_id"
    t.datetime "end_date"
    t.integer  "impressions1",                       :default => 0
    t.integer  "impressions2",                       :default => 0
    t.integer  "goals1",                             :default => 0
    t.integer  "goals2",                             :default => 0
    t.integer  "enabled",             :limit => 1,   :default => 1
  end

  create_table "form_field_groups", :force => true do |t|
    t.string   "name",       :limit => 200
    t.text     "intro"
    t.text     "outro"
    t.string   "klass",      :limit => 200
    t.integer  "order_by"
    t.datetime "updated_at"
    t.integer  "form_id"
    t.integer  "system_id"
  end

  create_table "form_field_types", :force => true do |t|
    t.string  "name",         :limit => 200
    t.string  "field_type",   :limit => 200
    t.text    "options"
    t.text    "html_options"
    t.text    "description"
    t.integer "has_asset",    :limit => 1,   :default => 0
    t.integer "system_id",    :limit => 1
    t.integer "allow_blank",  :limit => 1,   :default => 0
    t.integer "hidden",       :limit => 1,   :default => 0
  end

  add_index "form_field_types", ["system_id"], :name => "system_id"

  create_table "form_fields", :force => true do |t|
    t.integer "form_id"
    t.integer "display_order"
    t.integer "form_field_type_id"
    t.integer "is_mandatory"
    t.string  "name",                 :limit => 200
    t.integer "system_id",            :limit => 1
    t.string  "code_name",            :limit => 200
    t.text    "description"
    t.integer "form_field_group_id"
    t.text    "default_value"
    t.string  "geo_code_from_fields", :limit => 200
    t.integer "hidden",               :limit => 1,   :default => 0
  end

  add_index "form_fields", ["system_id"], :name => "system_id"

  create_table "form_submission_fields", :force => true do |t|
    t.integer "form_field_id"
    t.text    "value"
    t.integer "form_submission_id"
    t.integer "system_id",          :limit => 1
    t.float   "lat"
    t.float   "lon"
  end

  add_index "form_submission_fields", ["form_field_id"], :name => "form_field_id"
  add_index "form_submission_fields", ["form_submission_id", "form_field_id"], :name => "form_submission_id"
  add_index "form_submission_fields", ["system_id"], :name => "system_id"

  create_table "form_submissions", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.integer  "form_id"
    t.integer  "marked",     :limit => 1
    t.string   "ip",         :limit => 20
    t.integer  "system_id",  :limit => 1
    t.integer  "visible",    :limit => 1,  :default => 1
    t.integer  "f_id"
    t.datetime "updated_at"
    t.float    "lat"
    t.float    "lon"
  end

  add_index "form_submissions", ["form_id", "f_id"], :name => "form_id_2"
  add_index "form_submissions", ["form_id", "system_id"], :name => "form_id"
  add_index "form_submissions", ["system_id"], :name => "system_id"

  create_table "forms", :force => true do |t|
    t.string  "title",                  :limit => 200
    t.text    "body"
    t.string  "redirect_to",            :limit => 200
    t.text    "notify"
    t.string  "klass",                  :limit => 200
    t.string  "submit_label",           :limit => 200
    t.string  "url",                    :limit => 200
    t.integer "system_id",              :limit => 1
    t.integer "user_visible",           :limit => 1,    :default => 0
    t.integer "owner_visible",          :limit => 1,    :default => 0
    t.integer "owner_editable",         :limit => 1,    :default => 0
    t.integer "user_editable",          :limit => 1,    :default => 0
    t.integer "public_visible",         :limit => 1,    :default => 0
    t.integer "assignable",             :limit => 1,    :default => 0
    t.integer "user_creatable",         :limit => 1,    :default => 1
    t.integer "public_creatable",       :limit => 1,    :default => 1
    t.integer "locked_for_delete",      :limit => 1,    :default => 1
    t.text    "html"
    t.text    "body_after"
    t.string  "stylesheets",            :limit => 1000, :default => ""
    t.integer "log_activity",           :limit => 1,    :default => 1
    t.integer "visible_by_default",     :limit => 1,    :default => 1
    t.integer "use_captcha_above_risk",                 :default => 100
    t.text    "search_result_format"
  end

  add_index "forms", ["system_id"], :name => "system_id"

  create_table "forum_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "threads_per_page"
    t.integer  "posts_per_page"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "thread_order",                :limit => 4, :default => "desc"
    t.string   "post_order",                  :limit => 4, :default => ""
    t.integer  "receive_watch_notifications", :limit => 1, :default => 1
    t.integer  "receive_user2user_mail",      :limit => 1, :default => 1
  end

  create_table "galleries", :force => true do |t|
    t.string   "name",                :limit => 200
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.integer  "delay"
    t.integer  "width"
    t.integer  "height"
    t.integer  "transition_duration"
    t.string   "transition",          :limit => 200, :default => "fade"
    t.integer  "system_id",           :limit => 1
  end

  add_index "galleries", ["system_id"], :name => "system_id"

  create_table "gallery_assets", :force => true do |t|
    t.integer  "gallery_id"
    t.integer  "asset_id"
    t.datetime "created_at"
    t.integer  "display_order"
    t.string   "name",          :limit => 200
    t.string   "link",          :limit => 200
  end

  create_table "goals", :force => true do |t|
    t.string   "name",            :limit => 200
    t.integer  "user_id"
    t.integer  "system_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "goal_type",       :limit => 20
    t.string   "match_type",      :limit => 25
    t.string   "match_value",     :limit => 250
    t.text     "notes"
    t.integer  "session_minutes"
  end

  create_table "goals_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "goal_id"
    t.datetime "created_at"
    t.integer  "experiment_option"
  end

  create_table "group_users", :force => true do |t|
    t.integer "user_id"
    t.integer "group_id"
  end

  create_table "groups", :force => true do |t|
    t.string   "name",       :limit => 200
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "system_id",  :limit => 1
  end

  add_index "groups", ["system_id"], :name => "system_id"

  create_table "help_images", :force => true do |t|
    t.string   "image_file_name", :limit => 200
    t.datetime "updated_at"
  end

  create_table "helps", :force => true do |t|
    t.string   "name",       :limit => 200
    t.string   "path",       :limit => 200
    t.text     "body"
    t.datetime "updated_at"
  end

  create_table "html_assets", :force => true do |t|
    t.string   "name",        :limit => 200
    t.text     "body"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "user_id"
    t.integer  "system_id",   :limit => 1
    t.string   "file_type",   :limit => 20
    t.string   "fingerprint", :limit => 80
  end

  add_index "html_assets", ["system_id"], :name => "system_id"

  create_table "ip_countries", :force => true do |t|
    t.string  "ip_froms",     :limit => 20
    t.string  "ip_tos",       :limit => 20
    t.integer "ip_from",      :limit => 8
    t.integer "ip_to",        :limit => 8
    t.string  "country_code", :limit => 2
    t.string  "name",         :limit => 200
    t.integer "risk"
  end

  add_index "ip_countries", ["ip_to"], :name => "ip_to"

  create_table "kit_engagements", :force => true do |t|
    t.integer  "kit_session_id"
    t.string   "engage_type",    :limit => 20
    t.string   "value",          :limit => 200
    t.datetime "created_at"
    t.integer  "system_id"
  end

  create_table "kit_requests", :force => true do |t|
    t.integer  "kit_session_id"
    t.string   "url"
    t.string   "ip",             :limit => 20
    t.datetime "created_at"
    t.string   "referer",        :limit => 200
  end

  create_table "kit_sessions", :force => true do |t|
    t.string   "session_id",    :limit => 80
    t.integer  "user_id"
    t.datetime "first_request"
    t.datetime "last_request"
    t.integer  "page_views"
    t.integer  "system_id"
  end

  add_index "kit_sessions", ["session_id"], :name => "session_id", :unique => true

  create_table "layouts", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",        :limit => 80
    t.text     "body"
    t.string   "path",        :limit => 200
    t.string   "locale",      :limit => 40,   :default => "en"
    t.string   "handler",     :limit => 40
    t.integer  "partial",     :limit => 1,    :default => 0
    t.string   "format",      :limit => 40
    t.integer  "user_id"
    t.string   "stylesheets", :limit => 2000, :default => "application"
    t.integer  "system_id",   :limit => 1
    t.string   "javascripts", :limit => 1000
  end

  add_index "layouts", ["system_id"], :name => "system_id"

  create_table "locations", :force => true do |t|
    t.integer "subregion_id"
    t.string  "address1",     :limit => 200
    t.string  "address2",     :limit => 200
    t.string  "address3",     :limit => 200
    t.string  "city",         :limit => 200
    t.string  "postcode",     :limit => 20
    t.string  "country",      :limit => 200
    t.float   "latitude"
    t.float   "longitude"
    t.integer "system_id",                   :null => false
  end

  create_table "mappings", :force => true do |t|
    t.string   "source_url"
    t.string   "target_url"
    t.integer  "user_id"
    t.integer  "status_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "is_active",                :default => 1
    t.string   "params_url"
    t.integer  "is_page",     :limit => 1, :default => 1
    t.integer  "system_id",   :limit => 1
    t.integer  "hidden",      :limit => 1, :default => 0
    t.integer  "is_asset",    :limit => 1, :default => 0
  end

  add_index "mappings", ["source_url"], :name => "source_url"
  add_index "mappings", ["system_id", "hidden"], :name => "system_id_2"
  add_index "mappings", ["system_id"], :name => "system_id"

  create_table "menu_items", :force => true do |t|
    t.integer "parent_id"
    t.string  "name"
    t.string  "link_url"
    t.string  "title"
    t.integer "has_children"
    t.integer "menu_id"
    t.integer "order_by"
    t.integer "system_id"
  end

  create_table "menus", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.integer  "is_system_menu",    :limit => 1, :default => 0
    t.integer  "use_separator",     :limit => 1, :default => 0
    t.integer  "system_id",         :limit => 1
    t.integer  "can_have_children", :limit => 1, :default => 1
    t.integer  "can_cache",         :limit => 1, :default => 1
  end

  add_index "menus", ["system_id"], :name => "system_id"

  create_table "messages", :force => true do |t|
    t.integer  "conversation_id"
    t.integer  "user_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "system_id",       :limit => 1
  end

  add_index "messages", ["system_id"], :name => "system_id"

  create_table "newsletter_sends", :force => true do |t|
    t.integer  "newsletter_id"
    t.boolean  "is_test"
    t.datetime "sent_at"
    t.integer  "sent_by"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "newsletter_sents", :force => true do |t|
    t.integer  "newsletter_sends_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",               :limit => 200
    t.string   "status",              :limit => 200
    t.integer  "user_id"
  end

  create_table "newsletters", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "headers"
    t.text     "raw_mail"
    t.text     "content"
    t.string   "status",     :limit => 100
    t.integer  "system_id",  :limit => 1
  end

  add_index "newsletters", ["system_id"], :name => "system_id"

  create_table "notice_recipients", :force => true do |t|
    t.integer "notice_id"
    t.string  "recipient_type", :limit => 20
    t.string  "value",          :limit => 20
  end

  create_table "notices", :force => true do |t|
    t.string   "name",       :limit => 200
    t.text     "body"
    t.datetime "created_at"
    t.integer  "user_id"
    t.integer  "active",     :limit => 1,   :default => 0
    t.integer  "system_id"
  end

  create_table "notices_users", :force => true do |t|
    t.integer "notice_id"
    t.integer "user_id"
    t.integer "system_id"
  end

  create_table "order_items", :force => true do |t|
    t.integer  "order_id"
    t.string   "name",           :limit => 200
    t.float    "quantity"
    t.float    "unit_price"
    t.float    "tax_rate",                      :default => 0.0
    t.float    "total_price"
    t.datetime "created_at"
    t.string   "orderable_type", :limit => 200
    t.integer  "orderable_id"
    t.integer  "system_id"
  end

  create_table "order_payments", :force => true do |t|
    t.integer  "order_id"
    t.string   "status",               :limit => 200
    t.datetime "created_at"
    t.string   "ip_address",           :limit => 20
    t.string   "auth_code",            :limit => 20
    t.string   "threed_secure_status", :limit => 50
    t.string   "address_status",       :limit => 50
    t.string   "postcode_status",      :limit => 50
    t.string   "cv2_status",           :limit => 50
    t.string   "payment_type",         :limit => 20
    t.string   "card_type",            :limit => 20
    t.string   "card_identifier",      :limit => 20
    t.string   "tx_id",                :limit => 100
    t.datetime "processed_at"
    t.integer  "system_id"
    t.integer  "user_id"
  end

  create_table "orders", :force => true do |t|
    t.integer  "user_id"
    t.text     "description"
    t.string   "status",       :limit => 20
    t.datetime "created_at"
    t.string   "lastname",     :limit => 200
    t.string   "firstname",    :limit => 200
    t.string   "address1",     :limit => 200
    t.string   "address2",     :limit => 200
    t.string   "town",         :limit => 200
    t.string   "postcode",     :limit => 200
    t.string   "country",      :limit => 200
    t.string   "del_address1", :limit => 200
    t.string   "del_address2", :limit => 200
    t.string   "del_town",     :limit => 200
    t.string   "del_postcode", :limit => 200
    t.string   "del_country",  :limit => 200
    t.string   "email",        :limit => 200
    t.integer  "system_id"
  end

  create_table "page_comments", :force => true do |t|
    t.integer  "page_id"
    t.integer  "createdby_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "delta",        :limit => 1, :default => 1
    t.integer  "user_id"
  end

  create_table "page_contents", :force => true do |t|
    t.integer  "page_id"
    t.integer  "version"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "field_name", :limit => 80
    t.integer  "system_id"
  end

  create_table "page_edits", :force => true do |t|
    t.integer  "page_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "page_favourites", :force => true do |t|
    t.integer  "page_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "page_histories", :force => true do |t|
    t.integer  "page_id"
    t.integer  "createdby_id"
    t.string   "activity"
    t.text     "details"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "is_publishable",    :default => 0
    t.integer  "page_content_id"
    t.integer  "block_instance_id"
  end

  create_table "page_template_terms", :force => true do |t|
    t.integer  "page_template_id"
    t.integer  "form_field_type_id"
    t.integer  "created_by"
    t.string   "name"
    t.integer  "system_id"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "can_repeat",         :limit => 1, :default => 0
  end

  create_table "page_templates", :force => true do |t|
    t.string   "name"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "header"
    t.text     "footer"
    t.string   "page_type",                :limit => 20
    t.integer  "layout_id"
    t.string   "template_type",            :limit => 100
    t.integer  "display_order"
    t.integer  "is_mobile",                :limit => 1,    :default => 0
    t.integer  "mobile_version_id",                        :default => 0
    t.integer  "is_default",               :limit => 1,    :default => 0
    t.string   "stylesheets",              :limit => 1000
    t.integer  "system_id",                :limit => 1
    t.string   "javascripts",              :limit => 1000
    t.integer  "hidden",                   :limit => 1,    :default => 0
    t.integer  "user_id"
    t.integer  "allow_anonymous_comments", :limit => 1,    :default => 0
    t.integer  "allow_user_comments",      :limit => 1,    :default => 0
  end

  add_index "page_templates", ["system_id"], :name => "system_id"

  create_table "page_threads", :force => true do |t|
    t.integer "page_id"
    t.integer "topic_thread_id"
  end

  create_table "pages", :force => true do |t|
    t.string   "full_path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "category_id"
    t.string   "name"
    t.string   "title"
    t.integer  "status_id"
    t.text     "tags"
    t.integer  "is_deleted",               :limit => 1, :default => 0
    t.string   "page_name"
    t.string   "page_title"
    t.text     "meta_description"
    t.text     "meta_keywords"
    t.integer  "page_template_id"
    t.datetime "publish_at"
    t.datetime "published_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "edit_version"
    t.string   "subtype"
    t.text     "notes"
    t.integer  "in_sitemap",               :limit => 1, :default => 0
    t.integer  "mobile_dif",               :limit => 1, :default => 0
    t.integer  "system_id",                :limit => 1
    t.text     "header"
    t.integer  "locked",                   :limit => 1, :default => 0
    t.integer  "allow_anonymous_comments", :limit => 1, :default => 0
    t.integer  "allow_user_comments",      :limit => 1, :default => 0
  end

  add_index "pages", ["system_id"], :name => "system_id"

  create_table "post_reports", :force => true do |t|
    t.integer  "user_id"
    t.text     "comment"
    t.integer  "topic_post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preferences", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "system_id",  :limit => 1
  end

  add_index "preferences", ["system_id"], :name => "system_id"

  create_table "regions", :force => true do |t|
    t.string   "name",       :limit => 200
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "system_id",  :limit => 1
  end

  add_index "roles", ["system_id"], :name => "system_id"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "snippets", :force => true do |t|
    t.string   "name"
    t.text     "body"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "has_code"
    t.text     "description"
    t.integer  "system_id",    :limit => 1
    t.integer  "show_editors", :limit => 1, :default => 0
  end

  add_index "snippets", ["system_id"], :name => "system_id"

  create_table "statuses", :force => true do |t|
    t.string   "name"
    t.integer  "order_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "is_published", :limit => 1, :default => 0
    t.integer  "is_stub",      :limit => 1, :default => 0
    t.integer  "is_default",   :limit => 1, :default => 0
    t.integer  "system_id",    :limit => 1
  end

  add_index "statuses", ["system_id"], :name => "system_id"

  create_table "submission_checks", :force => true do |t|
    t.string   "check_code", :limit => 32, :null => false
    t.datetime "created_at"
  end

  add_index "submission_checks", ["check_code"], :name => "check_code", :unique => true

  create_table "subregions", :force => true do |t|
    t.integer  "region_id"
    t.string   "name",            :limit => 200
    t.datetime "updated_at"
    t.string   "postcode_prefix", :limit => 200
  end

  create_table "system_identifiers", :force => true do |t|
    t.integer "system_id"
    t.string  "ident_type",  :limit => 200
    t.string  "ident_value", :limit => 200
  end

  create_table "system_users", :force => true do |t|
    t.integer "user_id"
    t.integer "system_id"
  end

  add_index "system_users", ["user_id", "system_id"], :name => "user_id", :unique => true

  create_table "systems", :force => true do |t|
    t.string  "name",                :limit => 200
    t.integer "system_id",                          :default => 0
    t.string  "database_connection", :limit => 200
    t.string  "database_username",   :limit => 100
    t.string  "database_password",   :limit => 100
  end

  create_table "terms", :force => true do |t|
    t.integer  "page_id"
    t.integer  "metric"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "value"
    t.integer  "system_id",             :limit => 1
    t.integer  "page_template_term_id"
    t.string   "value_urlised"
  end

  add_index "terms", ["system_id"], :name => "system_id"

  create_table "thread_views", :force => true do |t|
    t.integer  "user_id"
    t.integer  "topic_thread_id"
    t.integer  "topic_post_id"
    t.datetime "email_sent"
  end

  add_index "thread_views", ["topic_thread_id", "user_id"], :name => "topic_thread_id", :unique => true
  add_index "thread_views", ["user_id", "topic_thread_id"], :name => "user_id", :unique => true

  create_table "ticket_sales", :force => true do |t|
    t.integer  "quantity"
    t.float    "unit_price"
    t.string   "email",             :limit => 200
    t.string   "firstname",         :limit => 100
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sellable_id"
    t.string   "sellable_type",     :limit => 200
    t.string   "telephone",         :limit => 200
    t.datetime "paid_at"
    t.float    "tax_rate"
    t.string   "lastname",          :limit => 100
    t.string   "payment_reference", :limit => 100
  end

  create_table "todos", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.datetime "closed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "delta",       :limit => 1, :default => 1
    t.integer  "system_id",   :limit => 1
  end

  add_index "todos", ["system_id"], :name => "system_id"

  create_table "topic_categories", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "read_access_level"
    t.integer  "write_access_level"
    t.integer  "display_order"
    t.string   "url"
    t.integer  "is_open",                         :default => 1
    t.integer  "show_title",         :limit => 1, :default => 1
    t.integer  "system_id",          :limit => 1
  end

  add_index "topic_categories", ["display_order"], :name => "display_order"
  add_index "topic_categories", ["system_id"], :name => "system_id"

  create_table "topic_post_edits", :force => true do |t|
    t.datetime "created_at"
    t.text     "raw_body"
    t.integer  "topic_post_id"
    t.integer  "user_id"
  end

  create_table "topic_post_votes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "topic_post_id"
    t.integer  "score"
    t.datetime "created_at"
  end

  create_table "topic_posts", :force => true do |t|
    t.integer  "topic_thread_id"
    t.integer  "created_by_user_id"
    t.text     "body"
    t.integer  "is_visible"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "moderation_comment"
    t.string   "ip",                           :limit => 15
    t.integer  "delta",                        :limit => 1,   :default => 1
    t.string   "created_by_user_display_name", :limit => 100
    t.integer  "system_id",                    :limit => 1
    t.integer  "score",                                       :default => 0
    t.text     "raw_body"
    t.integer  "post_number",                                 :default => 0
  end

  add_index "topic_posts", ["system_id"], :name => "system_id"
  add_index "topic_posts", ["topic_thread_id", "id", "is_visible"], :name => "topic_thread_id"

  create_table "topic_thread_users", :force => true do |t|
    t.integer  "topic_thread_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "email_sent"
  end

  create_table "topic_threads", :force => true do |t|
    t.integer  "topic_id"
    t.integer  "created_by_user_id"
    t.string   "title"
    t.text     "moderation_comment"
    t.integer  "last_post_by_user_id"
    t.integer  "post_count"
    t.integer  "is_locked"
    t.integer  "is_sticky"
    t.text     "locked_statement"
    t.integer  "is_visible"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "view_count",                                    :default => 0
    t.integer  "heat",                                          :default => 0
    t.datetime "last_post_at"
    t.integer  "delta",                          :limit => 1,   :default => 1
    t.string   "created_by_user_display_name",   :limit => 100
    t.string   "last_post_by_user_display_name", :limit => 100
    t.text     "thread_comment"
    t.integer  "first_post_id"
    t.integer  "system_id",                      :limit => 1
    t.integer  "old_id"
  end

  add_index "topic_threads", ["system_id"], :name => "system_id"
  add_index "topic_threads", ["topic_id", "id", "is_visible"], :name => "topic_id"

  create_table "topics", :force => true do |t|
    t.integer  "topic_category_id"
    t.string   "name"
    t.text     "description"
    t.integer  "read_access_level"
    t.integer  "write_access_level"
    t.integer  "is_open"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "display_order"
    t.string   "url"
    t.integer  "thread_count"
    t.datetime "last_post_at"
    t.text     "topic_comment"
    t.integer  "is_visible",                        :default => 1
    t.string   "image_file_name",    :limit => 200
    t.integer  "system_id",          :limit => 1
    t.integer  "old_forum_id"
    t.integer  "post_count",                        :default => 0
    t.integer  "last_thread_id"
    t.integer  "last_post_id"
  end

  add_index "topics", ["system_id"], :name => "system_id"

  create_table "user_assets", :force => true do |t|
    t.integer  "user_id"
    t.string   "asset_file_name"
    t.integer  "asset_file_size"
    t.string   "asset_content_type"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "user_attribute_values", :force => true do |t|
    t.integer  "user_id"
    t.integer  "user_attribute_id"
    t.string   "value"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "asset_file_name",    :limit => 200
    t.integer  "asset_size"
    t.string   "asset_content_type"
    t.integer  "system_id"
  end

  create_table "user_attributes", :force => true do |t|
    t.string   "name"
    t.integer  "admin_visible",      :limit => 1
    t.integer  "user_visible",       :limit => 1
    t.integer  "public_visible",     :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_visible",      :limit => 1
    t.integer  "owner_editable",     :limit => 1
    t.integer  "form_field_type_id"
    t.text     "description"
    t.integer  "is_mandatory",       :limit => 1,   :default => 0
    t.integer  "order_by",                          :default => 0
    t.integer  "system_id",          :limit => 1
    t.string   "code_name",          :limit => 200
    t.integer  "show_on_signup",     :limit => 1,   :default => 0
  end

  add_index "user_attributes", ["system_id"], :name => "system_id"

  create_table "user_links", :force => true do |t|
    t.integer "user_id"
    t.string  "label",         :limit => 40
    t.string  "url",           :limit => 80
    t.integer "in_new_window", :limit => 1,  :default => 0
  end

  add_index "user_links", ["user_id", "id"], :name => "user_id"

  create_table "user_notes", :force => true do |t|
    t.integer  "user_id"
    t.string   "category",      :limit => 100
    t.text     "description"
    t.integer  "created_by_id"
    t.datetime "created_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "failed_attempts",                       :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "banned_at"
    t.integer  "delta",                  :limit => 1,   :default => 1
    t.integer  "forum_level",                           :default => 1
    t.string   "display_name"
    t.integer  "subscribe_newsletter",   :limit => 1,   :default => 0
    t.integer  "email_failures",                        :default => 0
    t.integer  "spam_points"
    t.integer  "system_id",              :limit => 1
    t.integer  "old_user_id"
    t.integer  "forum_points",                          :default => 0
    t.integer  "forum_votes",                           :default => 0
    t.string   "password_salt",          :limit => 200
    t.integer  "forum_status"
  end

  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["system_id"], :name => "system_id"

  create_table "views", :force => true do |t|
    t.string   "name",             :limit => 200
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "header"
    t.text     "footer"
    t.string   "order_by",         :limit => 200
    t.text     "where_clause"
    t.integer  "per_page",                        :default => 10
    t.integer  "layout_id"
    t.integer  "page_template_id"
    t.string   "template_type",    :limit => 20
    t.integer  "system_id",        :limit => 1
  end

  add_index "views", ["system_id"], :name => "system_id"

  create_table "words", :force => true do |t|
    t.string  "name",             :limit => 40
    t.integer "is_insignificant", :limit => 1
  end

  add_index "words", ["name"], :name => "name", :unique => true

end
