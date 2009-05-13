# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090426200749) do

  create_table "activities", :force => true do |t|
    t.integer  "user_id"
    t.integer  "partner_id"
    t.string   "type",                 :limit => 60
    t.string   "status",               :limit => 8
    t.integer  "priority_id"
    t.integer  "endorsement_id"
    t.integer  "picture_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_user_only",                       :default => false
    t.integer  "comments_count",                     :default => 0
    t.integer  "activity_id"
    t.integer  "vote_id"
    t.integer  "change_id"
    t.integer  "other_user_id"
    t.integer  "tag_id"
    t.integer  "point_id"
    t.integer  "revision_id"
    t.integer  "capital_id"
    t.integer  "letter_id"
    t.integer  "ad_id"
    t.integer  "priority_chart_id"
    t.integer  "user_chart_id"
    t.integer  "document_id"
    t.integer  "document_revision_id"
  end

  add_index "activities", ["activity_id"], :name => "activity_activity_id"
  add_index "activities", ["ad_id"], :name => "activities_ad_id_index"
  add_index "activities", ["change_id"], :name => "activities_change_id_index"
  add_index "activities", ["created_at"], :name => "created_at"
  add_index "activities", ["document_id"], :name => "index_activities_on_document_id"
  add_index "activities", ["document_revision_id"], :name => "index_activities_on_document_revision_id"
  add_index "activities", ["is_user_only"], :name => "activity_is_user_only_index"
  add_index "activities", ["point_id"], :name => "activity_point_id_index"
  add_index "activities", ["priority_id"], :name => "activity_priority_id_index"
  add_index "activities", ["revision_id"], :name => "index_activities_on_revision_id"
  add_index "activities", ["status"], :name => "activity_status_index"
  add_index "activities", ["type"], :name => "activity_type_index"
  add_index "activities", ["updated_at"], :name => "activities_updated_at_index"
  add_index "activities", ["user_id"], :name => "activity_user_id_index"
  add_index "activities", ["vote_id"], :name => "activities_vote_id_index"

  create_table "ads", :force => true do |t|
    t.integer  "priority_id"
    t.integer  "user_id"
    t.integer  "show_ads_count",                 :default => 0
    t.integer  "shown_ads_count",                :default => 0
    t.integer  "cost"
    t.float    "per_user_cost"
    t.float    "spent",                          :default => 0.0
    t.integer  "yes_count",                      :default => 0
    t.integer  "no_count",                       :default => 0
    t.integer  "skip_count",                     :default => 0
    t.string   "status",          :limit => 40
    t.string   "content",         :limit => 140
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "finished_at"
    t.integer  "position",                       :default => 0
  end

  add_index "ads", ["priority_id"], :name => "ads_priority_id_index"
  add_index "ads", ["status"], :name => "ads_status_index"

  create_table "blast_templates", :force => true do |t|
    t.string   "name",       :limit => 60
    t.string   "subject",    :limit => 100
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blasts", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "status"
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.integer  "tag_id"
    t.string   "code",         :limit => 40
    t.integer  "clicks_count",               :default => 0
  end

  add_index "blasts", ["code"], :name => "blasts_code_index"
  add_index "blasts", ["name"], :name => "blasts_name_index"
  add_index "blasts", ["status"], :name => "blasts_status_index"
  add_index "blasts", ["type"], :name => "blasts_type_index"
  add_index "blasts", ["user_id"], :name => "blast_user_id_index"

  create_table "blurbs", :force => true do |t|
    t.string   "name",       :limit => 50
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blurbs", ["name"], :name => "index_blurbs_on_name"

  create_table "capitals", :force => true do |t|
    t.integer  "sender_id"
    t.integer  "recipient_id"
    t.integer  "capitalizable_id"
    t.string   "capitalizable_type"
    t.integer  "amount",                           :default => 0
    t.string   "type",               :limit => 60
    t.string   "note"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "capitals", ["recipient_id"], :name => "capitals_recipient_id_index"
  add_index "capitals", ["sender_id"], :name => "capitals_sender_id_index"
  add_index "capitals", ["type"], :name => "capitals_type_index"

  create_table "changes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "priority_id"
    t.integer  "new_priority_id"
    t.string   "type"
    t.string   "status"
    t.integer  "yes_votes",             :default => 0
    t.integer  "no_votes",              :default => 0
    t.datetime "sent_at"
    t.datetime "approved_at"
    t.datetime "declined_at"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position",              :default => 0
    t.integer  "cost"
    t.integer  "estimated_votes_count", :default => 0
    t.integer  "votes_count",           :default => 0
    t.boolean  "is_endorsers",          :default => true
    t.boolean  "is_opposers",           :default => true
    t.boolean  "is_flip",               :default => false
  end

  add_index "changes", ["new_priority_id"], :name => "changes_new_priority_id_index"
  add_index "changes", ["priority_id"], :name => "changes_priority_id_index"
  add_index "changes", ["status"], :name => "changes_status_index"
  add_index "changes", ["type"], :name => "changes_type_index"
  add_index "changes", ["user_id"], :name => "changes_user_id_index"

  create_table "client_applications", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "support_url"
    t.string   "callback_url"
    t.string   "key",          :limit => 50
    t.string   "secret",       :limit => 50
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "client_applications", ["key"], :name => "index_client_applications_on_key", :unique => true

  create_table "comments", :force => true do |t|
    t.integer  "activity_id"
    t.integer  "user_id"
    t.string   "status"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_endorser",  :default => false
    t.string   "ip_address"
    t.string   "user_agent"
    t.string   "referrer"
    t.boolean  "is_opposer",   :default => false
    t.text     "content_html"
    t.integer  "flags_count",  :default => 0
  end

  add_index "comments", ["activity_id"], :name => "comments_activity_id"
  add_index "comments", ["status", "activity_id"], :name => "index_comments_on_status_and_activity_id"
  add_index "comments", ["status"], :name => "comments_status"
  add_index "comments", ["user_id"], :name => "comments_user_id"

  create_table "constituents", :force => true do |t|
    t.integer  "legislator_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "constituents", ["legislator_id", "user_id"], :name => "index_constituents_on_legislator_id_and_user_id"

  create_table "document_qualities", :force => true do |t|
    t.integer  "user_id"
    t.integer  "document_id"
    t.integer  "value",                     :default => 0
    t.string   "ip_address",  :limit => 16
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "document_qualities", ["document_id"], :name => "index_document_qualities_on_document_id"
  add_index "document_qualities", ["user_id"], :name => "index_document_qualities_on_user_id"

  create_table "document_revisions", :force => true do |t|
    t.integer  "document_id"
    t.integer  "user_id"
    t.integer  "value",                       :default => 0, :null => false
    t.string   "status",       :limit => 30
    t.string   "name",         :limit => 60
    t.string   "ip_address",   :limit => 16
    t.string   "user_agent",   :limit => 150
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "content"
    t.text     "content_diff"
    t.integer  "word_count",                  :default => 0
    t.text     "content_html"
  end

  add_index "document_revisions", ["document_id"], :name => "index_document_revisions_on_document_id"
  add_index "document_revisions", ["status"], :name => "index_document_revisions_on_status"
  add_index "document_revisions", ["user_id"], :name => "index_document_revisions_on_user_id"

  create_table "documents", :force => true do |t|
    t.integer  "revision_id"
    t.integer  "priority_id"
    t.integer  "user_id"
    t.integer  "value",                                  :default => 0
    t.string   "status",                   :limit => 20
    t.string   "name",                     :limit => 60
    t.string   "cached_issue_list"
    t.string   "author_sentence"
    t.integer  "revisions_count",                        :default => 0
    t.integer  "helpful_count",                          :default => 0
    t.integer  "unhelpful_count",                        :default => 0
    t.integer  "discussions_count",                      :default => 0
    t.integer  "endorser_helpful_count",                 :default => 0
    t.integer  "opposer_helpful_count",                  :default => 0
    t.integer  "neutral_helpful_count",                  :default => 0
    t.integer  "endorser_unhelpful_count",               :default => 0
    t.integer  "opposer_unhelpful_count",                :default => 0
    t.integer  "neutral_unhelpful_count",                :default => 0
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "content"
    t.integer  "word_count",                             :default => 0
    t.text     "content_html"
    t.integer  "sphinx_index",                           :default => 3
    t.float    "score",                                  :default => 0.0
    t.float    "endorser_score",                         :default => 0.0
    t.float    "opposer_score",                          :default => 0.0
    t.float    "neutral_score",                          :default => 0.0
  end

  add_index "documents", ["priority_id"], :name => "index_documents_on_priority_id"
  add_index "documents", ["revision_id"], :name => "index_documents_on_revision_id"
  add_index "documents", ["status"], :name => "index_documents_on_status"
  add_index "documents", ["user_id"], :name => "index_documents_on_user_id"

  create_table "email_templates", :force => true do |t|
    t.string   "name",       :limit => 50
    t.string   "subject",    :limit => 150
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_templates", ["name"], :name => "index_email_templates_on_name"

  create_table "endorsements", :force => true do |t|
    t.string   "status",      :limit => 50
    t.integer  "position"
    t.integer  "partner_id"
    t.integer  "priority_id"
    t.integer  "user_id"
    t.string   "ip_address",  :limit => 16
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "referral_id"
    t.integer  "value",                     :default => 1
  end

  add_index "endorsements", ["partner_id"], :name => "endorsements_partner_id_index"
  add_index "endorsements", ["position"], :name => "position"
  add_index "endorsements", ["priority_id"], :name => "endorsements_priority_id_index"
  add_index "endorsements", ["status", "priority_id", "user_id", "value"], :name => "endorsements_status_pid_uid"
  add_index "endorsements", ["status"], :name => "endorsements_status_index"
  add_index "endorsements", ["user_id"], :name => "endorsements_user_id_index"
  add_index "endorsements", ["value"], :name => "value"

  create_table "facebook_templates", :force => true do |t|
    t.string "template_name", :null => false
    t.string "content_hash",  :null => false
    t.string "bundle_id"
  end

  add_index "facebook_templates", ["template_name"], :name => "index_facebook_templates_on_template_name", :unique => true

  create_table "feeds", :force => true do |t|
    t.string   "name"
    t.string   "website_link"
    t.string   "feed_link"
    t.string   "cached_issue_list"
    t.datetime "crawled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "followings", :force => true do |t|
    t.integer  "user_id"
    t.integer  "other_user_id"
    t.integer  "value",         :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "followings", ["other_user_id"], :name => "followings_other_user_id_index"
  add_index "followings", ["user_id"], :name => "followings_user_id_index"

  create_table "governments", :force => true do |t|
  end

  create_table "legislators", :force => true do |t|
    t.string   "name",               :limit => 100
    t.string   "fullname",           :limit => 100
    t.string   "nickname",           :limit => 30
    t.string   "title",              :limit => 10
    t.string   "firstname",          :limit => 60
    t.string   "middlename",         :limit => 20
    t.string   "lastname",           :limit => 60
    t.string   "name_suffix",        :limit => 5
    t.string   "gender",             :limit => 1
    t.string   "congress_office",    :limit => 200
    t.string   "party",              :limit => 1
    t.string   "state",              :limit => 2
    t.string   "district",           :limit => 15
    t.string   "senate_class",       :limit => 10
    t.boolean  "in_office",                         :default => true
    t.integer  "govtrack_id"
    t.integer  "votesmart_id"
    t.string   "fec_id",             :limit => 10
    t.string   "crp_id",             :limit => 10
    t.string   "bioguide_id",        :limit => 10
    t.string   "phone",              :limit => 20
    t.string   "fax",                :limit => 20
    t.string   "email",              :limit => 80
    t.string   "webform",            :limit => 100
    t.string   "website",            :limit => 100
    t.string   "twitter_id",         :limit => 20
    t.string   "congresspedia_url",  :limit => 100
    t.string   "youtube_url",        :limit => 50
    t.integer  "constituents_count",                :default => 0
    t.datetime "last_crawled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "short_name",         :limit => 30
  end

  add_index "legislators", ["govtrack_id"], :name => "index_legislators_on_govtrack_id"
  add_index "legislators", ["name"], :name => "index_legislators_on_name"
  add_index "legislators", ["short_name"], :name => "index_legislators_on_short_name"
  add_index "legislators", ["user_id"], :name => "index_legislators_on_user_id"

  create_table "letters", :force => true do |t|
    t.integer  "user_id"
    t.string   "type",       :limit => 60
    t.boolean  "is_public"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.integer  "sender_id"
    t.integer  "recipient_id"
    t.string   "type",         :limit => 60
    t.string   "status",       :limit => 20
    t.string   "title",        :limit => 60
    t.text     "content"
    t.datetime "sent_at"
    t.datetime "read_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "messages", ["recipient_id"], :name => "messages_recipient_id_index"
  add_index "messages", ["sender_id"], :name => "messages_sender_id_index"
  add_index "messages", ["status"], :name => "messages_status_index"
  add_index "messages", ["type"], :name => "messages_type_index"

  create_table "notifications", :force => true do |t|
    t.integer  "sender_id"
    t.integer  "recipient_id"
    t.string   "status",          :limit => 20
    t.string   "type",            :limit => 60
    t.integer  "notifiable_id"
    t.string   "notifiable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "sent_at"
    t.datetime "read_at"
    t.datetime "processed_at"
    t.datetime "deleted_at"
  end

  add_index "notifications", ["notifiable_type", "notifiable_id"], :name => "index_notifications_on_notifiable_type_and_notifiable_id"
  add_index "notifications", ["recipient_id"], :name => "index_notifications_on_recipient_id"
  add_index "notifications", ["sender_id"], :name => "index_notifications_on_sender_id"
  add_index "notifications", ["status", "type"], :name => "index_notifications_on_status_and_type"

  create_table "oauth_nonces", :force => true do |t|
    t.string   "nonce"
    t.integer  "timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_nonces", ["nonce", "timestamp"], :name => "index_oauth_nonces_on_nonce_and_timestamp", :unique => true

  create_table "oauth_tokens", :force => true do |t|
    t.integer  "user_id"
    t.string   "type",                  :limit => 20
    t.integer  "client_application_id"
    t.string   "token",                 :limit => 50
    t.string   "secret",                :limit => 50
    t.datetime "authorized_at"
    t.datetime "invalidated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_tokens", ["token"], :name => "index_oauth_tokens_on_token", :unique => true

  create_table "pages", :force => true do |t|
    t.string   "name",       :limit => 100
    t.string   "short_name", :limit => 30
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "link_name",  :limit => 60
  end

  create_table "partners", :force => true do |t|
    t.string   "name",             :limit => 60
    t.string   "short_name",       :limit => 20
    t.integer  "picture_id"
    t.integer  "is_optin",         :limit => 1,  :default => 0,         :null => false
    t.string   "optin_text",       :limit => 60
    t.string   "privacy_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "is_active",        :limit => 1,  :default => 1,         :null => false
    t.string   "status",                         :default => "passive"
    t.integer  "users_count",                    :default => 0
    t.string   "website"
    t.datetime "deleted_at"
    t.string   "ip_address",       :limit => 16
    t.boolean  "is_daily_summary",               :default => true
    t.string   "unsubscribe_url"
    t.string   "subscribe_url"
  end

  add_index "partners", ["short_name"], :name => "short_name"
  add_index "partners", ["status"], :name => "status"

  create_table "pictures", :force => true do |t|
    t.string   "name",         :limit => 200
    t.integer  "height",       :limit => 8
    t.integer  "width",        :limit => 8
    t.string   "content_type", :limit => 100
    t.binary   "data",         :limit => 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "point_qualities", :force => true do |t|
    t.integer  "user_id"
    t.integer  "point_id"
    t.boolean  "value",                    :default => true
    t.string   "ip_address", :limit => 16
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "point_qualities", ["point_id"], :name => "point_id"
  add_index "point_qualities", ["user_id", "point_id"], :name => "user_and_point_id"
  add_index "point_qualities", ["user_id"], :name => "user_id"

  create_table "points", :force => true do |t|
    t.integer  "revision_id"
    t.integer  "priority_id"
    t.integer  "other_priority_id"
    t.integer  "user_id"
    t.integer  "value",                                  :default => 0
    t.integer  "revisions_count",                        :default => 0
    t.string   "status",                   :limit => 50
    t.string   "name",                     :limit => 60
    t.text     "content"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "website"
    t.string   "author_sentence"
    t.integer  "helpful_count",                          :default => 0
    t.integer  "unhelpful_count",                        :default => 0
    t.integer  "discussions_count",                      :default => 0
    t.integer  "endorser_helpful_count",                 :default => 0
    t.integer  "opposer_helpful_count",                  :default => 0
    t.integer  "endorser_unhelpful_count",               :default => 0
    t.integer  "opposer_unhelpful_count",                :default => 0
    t.integer  "neutral_helpful_count",                  :default => 0
    t.integer  "neutral_unhelpful_count",                :default => 0
    t.integer  "sphinx_index",                           :default => 2
    t.float    "score",                                  :default => 0.0
    t.float    "endorser_score",                         :default => 0.0
    t.float    "opposer_score",                          :default => 0.0
    t.float    "neutral_score",                          :default => 0.0
  end

  add_index "points", ["other_priority_id"], :name => "index_points_on_other_priority_id"
  add_index "points", ["priority_id"], :name => "index_points_on_priority_id"
  add_index "points", ["revision_id"], :name => "index_points_on_revision_id"
  add_index "points", ["status"], :name => "index_points_on_status"
  add_index "points", ["user_id"], :name => "index_points_on_user_id"

  create_table "priorities", :force => true do |t|
    t.integer  "position",                               :default => 0, :null => false
    t.integer  "user_id"
    t.string   "name",                    :limit => 140
    t.integer  "endorsements_count",                     :default => 0, :null => false
    t.string   "status",                  :limit => 50
    t.string   "ip_address",              :limit => 16
    t.datetime "deleted_at"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position_1hr",                           :default => 0, :null => false
    t.integer  "position_24hr",                          :default => 0, :null => false
    t.integer  "position_7days",                         :default => 0, :null => false
    t.integer  "position_30days",                        :default => 0, :null => false
    t.integer  "position_1hr_change",                    :default => 0, :null => false
    t.integer  "position_24hr_change",                   :default => 0, :null => false
    t.integer  "position_7days_change",                  :default => 0, :null => false
    t.integer  "position_30days_change",                 :default => 0, :null => false
    t.integer  "change_id"
    t.string   "cached_issue_list"
    t.integer  "up_endorsements_count",                  :default => 0
    t.integer  "down_endorsements_count",                :default => 0
    t.integer  "points_count",                           :default => 0
    t.integer  "up_points_count",                        :default => 0
    t.integer  "down_points_count",                      :default => 0
    t.integer  "neutral_points_count",                   :default => 0
    t.integer  "discussions_count",                      :default => 0
    t.integer  "relationships_count",                    :default => 0
    t.string   "search_query"
    t.integer  "changes_count",                          :default => 0
    t.integer  "obama_status",                           :default => 0
    t.integer  "obama_value",                            :default => 0
    t.datetime "status_changed_at"
    t.integer  "score",                                  :default => 0
    t.integer  "up_documents_count",                     :default => 0
    t.integer  "down_documents_count",                   :default => 0
    t.integer  "neutral_documents_count",                :default => 0
    t.integer  "documents_count",                        :default => 0
    t.integer  "sphinx_index",                           :default => 1
  end

  add_index "priorities", ["obama_status"], :name => "index_priorities_on_obama_status"
  add_index "priorities", ["obama_value"], :name => "index_priorities_on_obama_value"
  add_index "priorities", ["position"], :name => "priorities_position_index"
  add_index "priorities", ["status"], :name => "priorities_status_index"
  add_index "priorities", ["user_id"], :name => "priorities_user_id_index"

  create_table "priority_charts", :force => true do |t|
    t.integer  "priority_id"
    t.integer  "date_year"
    t.integer  "date_month"
    t.integer  "date_day"
    t.integer  "position"
    t.integer  "up_count"
    t.integer  "down_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "volume_count"
    t.float    "change_percent", :default => 0.0
    t.integer  "change",         :default => 0
  end

  add_index "priority_charts", ["date_year", "date_month", "date_day"], :name => "priority_chart_date_index"
  add_index "priority_charts", ["priority_id"], :name => "priority_chart_priority_index"

  create_table "profiles", :force => true do |t|
    t.integer  "user_id"
    t.text     "bio"
    t.text     "bio_html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "profiles", ["user_id"], :name => "index_profiles_on_user_id"

  create_table "rankings", :force => true do |t|
    t.integer  "priority_id"
    t.integer  "version",            :default => 0
    t.integer  "position"
    t.integer  "endorsements_count", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rankings", ["created_at"], :name => "rankings_created_at_index"
  add_index "rankings", ["priority_id"], :name => "rankings_priority_id"
  add_index "rankings", ["version"], :name => "rankings_version_index"

  create_table "relationships", :force => true do |t|
    t.integer  "priority_id"
    t.integer  "other_priority_id"
    t.string   "type",              :limit => 70
    t.integer  "percentage"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "relationships", ["other_priority_id"], :name => "relationships_other_priority_index"
  add_index "relationships", ["priority_id"], :name => "relationships_priority_index"
  add_index "relationships", ["type"], :name => "relationships_type_index"

  create_table "research_tasks", :force => true do |t|
    t.integer  "document_id"
    t.integer  "requester_id"
    t.integer  "tag_id"
    t.integer  "legislator_id"
    t.string   "requester_name",         :limit => 100
    t.string   "requester_organization", :limit => 100
    t.string   "requester_email",        :limit => 100
    t.boolean  "is_official_request",                   :default => false
    t.string   "name",                   :limit => 60
    t.text     "content"
    t.datetime "finished_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "research_tasks", ["document_id"], :name => "index_research_tasks_on_document_id"
  add_index "research_tasks", ["legislator_id"], :name => "index_research_tasks_on_legislator_id"
  add_index "research_tasks", ["requester_id"], :name => "index_research_tasks_on_requester_id"
  add_index "research_tasks", ["tag_id"], :name => "index_research_tasks_on_tag_id"

  create_table "revisions", :force => true do |t|
    t.integer  "point_id"
    t.integer  "user_id"
    t.integer  "value",                            :default => 0, :null => false
    t.string   "status",            :limit => 50
    t.string   "name",              :limit => 60
    t.text     "content"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ip_address",        :limit => 16
    t.string   "user_agent",        :limit => 150
    t.string   "website",           :limit => 100
    t.text     "content_diff"
    t.integer  "other_priority_id"
  end

  add_index "revisions", ["other_priority_id"], :name => "index_revisions_on_other_priority_id"
  add_index "revisions", ["point_id"], :name => "index_revisions_on_point_id"
  add_index "revisions", ["status"], :name => "index_revisions_on_status"
  add_index "revisions", ["user_id"], :name => "index_revisions_on_user_id"

  create_table "shown_ads", :force => true do |t|
    t.integer  "ad_id"
    t.integer  "user_id"
    t.integer  "value",                     :default => 0
    t.string   "ip_address", :limit => 16
    t.string   "user_agent", :limit => 100
    t.string   "referrer",   :limit => 100
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "seen_count",                :default => 1
  end

  add_index "shown_ads", ["ad_id", "user_id"], :name => "ad_id"

  create_table "signups", :force => true do |t|
    t.integer  "partner_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ip_address", :limit => 16
  end

  add_index "signups", ["partner_id"], :name => "signups_partner_id"
  add_index "signups", ["user_id"], :name => "signups_user_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type",   :limit => 50
    t.string   "taggable_type", :limit => 50
    t.string   "context",       :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string   "name",                      :limit => 60
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "top_priority_id"
    t.integer  "up_endorsers_count",                      :default => 0
    t.integer  "down_endorsers_count",                    :default => 0
    t.integer  "controversial_priority_id"
    t.integer  "rising_priority_id"
    t.integer  "obama_priority_id"
    t.integer  "webpages_count",                          :default => 0
    t.integer  "priorities_count",                        :default => 0
    t.integer  "feeds_count",                             :default => 0
  end

  add_index "tags", ["top_priority_id"], :name => "tag_top_priority_id_index"

  create_table "unsubscribes", :force => true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.text     "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_comments_subscribed",      :default => false
    t.boolean  "is_votes_subscribed",         :default => false
    t.boolean  "is_newsletter_subscribed",    :default => false
    t.boolean  "is_point_changes_subscribed", :default => false
    t.boolean  "is_messages_subscribed",      :default => false
    t.boolean  "is_followers_subscribed",     :default => true
    t.boolean  "is_finished_subscribed",      :default => true
  end

  create_table "user_charts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "date_year"
    t.integer  "date_month"
    t.integer  "date_day"
    t.integer  "position"
    t.integer  "up_count"
    t.integer  "down_count"
    t.integer  "volume_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_charts", ["date_year", "date_month", "date_day"], :name => "user_chart_date_index"
  add_index "user_charts", ["user_id"], :name => "user_chart_user_index"

  create_table "user_contacts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "other_user_id"
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "following_id"
    t.integer  "facebook_uid"
    t.datetime "sent_at"
    t.datetime "accepted_at"
    t.boolean  "is_from_realname",               :default => false
    t.string   "status",           :limit => 30
  end

  add_index "user_contacts", ["email"], :name => "index_user_contacts_on_email"
  add_index "user_contacts", ["facebook_uid"], :name => "index_user_contacts_on_facebook_uid"
  add_index "user_contacts", ["following_id"], :name => "index_user_contacts_on_following_id"
  add_index "user_contacts", ["other_user_id"], :name => "index_user_contacts_on_other_user_id"
  add_index "user_contacts", ["status"], :name => "index_user_contacts_on_status"
  add_index "user_contacts", ["user_id"], :name => "user_contacts_user_id_index"

  create_table "user_rankings", :force => true do |t|
    t.integer  "user_id"
    t.integer  "version",        :default => 0
    t.integer  "position"
    t.integer  "capitals_count", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_rankings", ["created_at"], :name => "rankings_created_at_index"
  add_index "user_rankings", ["user_id"], :name => "rankings_user_id"
  add_index "user_rankings", ["version"], :name => "rankings_version_index"

  create_table "users", :force => true do |t|
    t.string   "login",                        :limit => 40
    t.string   "email",                        :limit => 100
    t.string   "crypted_password",             :limit => 40
    t.string   "salt",                         :limit => 40
    t.string   "first_name",                   :limit => 100
    t.string   "last_name",                    :limit => 100
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "activated_at"
    t.string   "activation_code",              :limit => 60
    t.string   "remember_token",               :limit => 60
    t.datetime "remember_token_expires_at"
    t.integer  "picture_id"
    t.string   "status",                       :limit => 30,  :default => "passive"
    t.integer  "partner_id"
    t.datetime "deleted_at"
    t.string   "ip_address",                   :limit => 16
    t.datetime "loggedin_at"
    t.string   "zip",                          :limit => 10
    t.date     "birth_date"
    t.string   "twitter_login",                :limit => 15
    t.string   "digg_login",                   :limit => 15
    t.string   "youtube_login",                :limit => 20
    t.string   "website",                      :limit => 150
    t.boolean  "is_mergeable",                                :default => true
    t.integer  "referral_id"
    t.boolean  "is_subscribed",                               :default => true
    t.string   "user_agent",                   :limit => 200
    t.string   "referrer",                     :limit => 200
    t.boolean  "is_comments_subscribed",                      :default => true
    t.boolean  "is_votes_subscribed",                         :default => true
    t.boolean  "is_newsletter_subscribed",                    :default => true
    t.boolean  "is_tagger",                                   :default => false
    t.integer  "endorsements_count",                          :default => 0
    t.integer  "up_endorsements_count",                       :default => 0
    t.integer  "down_endorsements_count",                     :default => 0
    t.integer  "up_issues_count",                             :default => 0
    t.integer  "down_issues_count",                           :default => 0
    t.integer  "comments_count",                              :default => 0
    t.float    "score",                                       :default => 0.1
    t.boolean  "is_point_changes_subscribed",                 :default => true
    t.boolean  "is_messages_subscribed",                      :default => true
    t.integer  "capitals_count",                              :default => 0
    t.integer  "twitter_count",                               :default => 0
    t.integer  "followers_count",                             :default => 0
    t.integer  "followings_count",                            :default => 0
    t.integer  "ignorers_count",                              :default => 0
    t.integer  "ignorings_count",                             :default => 0
    t.integer  "position_1hr",                                :default => 0
    t.integer  "position_24hr",                               :default => 0
    t.integer  "position_7days",                              :default => 0
    t.integer  "position_30days",                             :default => 0
    t.integer  "position_1hr_change",                         :default => 0
    t.integer  "position_24hr_change",                        :default => 0
    t.integer  "position_7days_change",                       :default => 0
    t.integer  "position_30days_change",                      :default => 0
    t.integer  "position",                                    :default => 0
    t.boolean  "is_followers_subscribed",                     :default => true
    t.integer  "partner_referral_id"
    t.integer  "ads_count",                                   :default => 0
    t.integer  "changes_count",                               :default => 0
    t.string   "google_token",                 :limit => 30
    t.integer  "top_endorsement_id"
    t.boolean  "is_finished_subscribed",                      :default => true
    t.integer  "contacts_count",                              :default => 0
    t.integer  "contacts_members_count",                      :default => 0
    t.integer  "contacts_invited_count",                      :default => 0
    t.integer  "contacts_not_invited_count",                  :default => 0
    t.datetime "google_crawled_at"
    t.integer  "facebook_uid"
    t.string   "city",                         :limit => 80
    t.string   "state",                        :limit => 50
    t.integer  "documents_count",                             :default => 0
    t.integer  "document_revisions_count",                    :default => 0
    t.integer  "points_count",                                :default => 0
    t.float    "index_24hr_change",                           :default => 0.0
    t.float    "index_7days_change",                          :default => 0.0
    t.float    "index_30days_change",                         :default => 0.0
    t.integer  "received_notifications_count",                :default => 0
    t.integer  "unread_notifications_count",                  :default => 0
    t.string   "rss_code",                     :limit => 40
    t.integer  "point_revisions_count",                       :default => 0
    t.integer  "qualities_count",                             :default => 0
    t.integer  "constituents_count",                          :default => 0
    t.string   "address",                      :limit => 100
    t.integer  "warnings_count",                              :default => 0
    t.datetime "probation_at"
    t.datetime "suspended_at"
    t.integer  "referrals_count",                             :default => 0
    t.boolean  "is_admin",                                    :default => false
  end

  add_index "users", ["facebook_uid"], :name => "index_users_on_facebook_uid"
  add_index "users", ["partner_id"], :name => "user_partner_id"
  add_index "users", ["rss_code"], :name => "index_users_on_rss_code"
  add_index "users", ["status"], :name => "status"

  create_table "votes", :force => true do |t|
    t.integer  "change_id"
    t.integer  "user_id"
    t.string   "code"
    t.string   "status"
    t.datetime "voted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "value",      :default => 1
  end

  add_index "votes", ["change_id"], :name => "votes_change_id_index"
  add_index "votes", ["code"], :name => "votes_code_index"
  add_index "votes", ["status"], :name => "votes_status_index"
  add_index "votes", ["user_id"], :name => "votes_user_id_index"

  create_table "webpages", :force => true do |t|
    t.integer  "user_id"
    t.integer  "picture_id"
    t.string   "status",            :limit => 20
    t.string   "url"
    t.string   "title"
    t.string   "description"
    t.datetime "crawled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "content_type"
    t.string   "charset"
    t.string   "content_encoding"
    t.datetime "published_at"
    t.string   "cached_issue_list", :limit => 150
    t.integer  "feed_id"
    t.string   "domain",            :limit => 100
  end

  add_index "webpages", ["feed_id"], :name => "index_webpages_on_feed_id"
  add_index "webpages", ["status"], :name => "status"
  add_index "webpages", ["user_id"], :name => "webpages_user_id_index"

end
