class AddGovernmentAndColorScheme < ActiveRecord::Migration
  def self.up
    create_table "color_schemes" do |t|
      t.string "nav_background",  :limit => 6, :default => "f0f0f0"
      t.string "nav_text",  :limit => 6, :default => "000000"
      t.string "nav_selected_background", :limit => 6, :default => "dddddd"
      t.string "nav_selected_text", :limit => 6, :default => "000000"
      t.string "nav_hover_background",  :limit => 6, :default => "13499b"
      t.string "nav_hover_text",  :limit => 6, :default => "ffffff"
      t.string "background",  :limit => 6, :default => "ffffff"
      t.string "box", :limit => 6, :default => "f0f0f0"
      t.string "text",  :limit => 6, :default => "444444"
      t.string "link",  :limit => 6, :default => "13499b"
      t.string "heading",   :limit => 6, :default => "000000"
      t.string "sub_heading", :limit => 6, :default => "999999"
      t.string "greyed_out",  :limit => 6, :default => "999999"
      t.string "border",:limit => 6, :default => "dddddd"
      t.string "error", :limit => 6, :default => "bc0000"
      t.string "error_text",  :limit => 6, :default => "ffffff"
      t.string "down",  :limit => 6, :default => "bc0000"
      t.string "up",  :limit => 6, :default => "009933"
      t.string "action_button",   :limit => 6, :default => "ffff99"
      t.string "action_button_border",  :limit => 6, :default => "ffcc00"
      t.string "endorsed_button", :limit => 6, :default => "009933"
      t.string "endorsed_button_text",  :limit => 6, :default => "ffffff"
      t.string "opposed_button",  :limit => 6, :default => "bc0000"
      t.string "opposed_button_text",   :limit => 6, :default => "ffffff"
      t.string "compromised_button",:limit => 6, :default => "ffcc00"
      t.string "compromised_button_text", :limit => 6, :default => "ffffff"
      t.string "grey_button", :limit => 6, :default => "f0f0f0"
      t.string "grey_button_border",:limit => 6, :default => "cccccc"
      t.string "fonts", :limit => 50, :default => "Arial, Helvetica, sans-serif"
      t.integer  "background_picture_id"
      t.boolean  "background_tiled",  :default => false
      t.string "main",  :limit => 6,  :default => "FFFFFF"
      t.string "comments",  :limit => 6,  :default => "F0F0F0"
      t.string "comments_text",   :limit => 6,  :default => "444444"
      t.string "input", :limit => 6,  :default => "444444"
      t.string "box_text",  :limit => 6,  :default => "444444"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "is_featured", :default => false      
    end
    add_column :governments, :status, :string, :limit => 30
    add_column :governments, :short_name, :string, :limit => 20
    add_column :governments, :domain_name, :string, :limit => 60
    add_column :governments, :layout, :string, :limit => 20
    add_column :governments, :name, :string,:limit => 60
    add_column :governments, :tagline, :string, :limit => 100
    add_column :governments, :email, :string, :limit => 100
    add_column :governments, :is_public, :boolean, :default => true
    add_column :governments, :created_at, :datetime
    add_column :governments, :updated_at, :datetime
    add_column :governments, :db_name, :string,:limit => 20
    add_column :governments, :official_user_id, :integer
    add_column :governments, :official_user_short_name, :string, :limit => 25
    add_column :governments, :target, :string, :limit => 30
    add_column :governments, :is_tags, :boolean,:default => true
    add_column :governments, :is_facebook, :boolean, :default => true
    add_column :governments, :is_legislators, :boolean, :default => false
    add_column :governments, :admin_name, :string, :limit => 60
    add_column :governments, :admin_email, :string, :limit => 100
    add_column :governments, :google_analytics_code, :string,  :limit => 15
    add_column :governments, :quantcast_code, :string, :limit => 20
    add_column :governments, :tags_name, :string, :limit => 20,  :default => "Category"
    add_column :governments, :briefing_name, :string, :limit => 20,  :default => "Briefing Room"
    add_column :governments, :currency_name, :string, :limit => 30,  :default => "political capital"
    add_column :governments, :currency_short_name, :string, :limit => 3, :default => "pc"
    add_column :governments, :homepage, :string,  :limit => 20,  :default => "top"
    add_column :governments, :priorities_count, :integer, :default => 0
    add_column :governments, :points_count, :integer, :default => 0
    add_column :governments, :documents_count, :integer, :default => 0
    add_column :governments, :users_count, :integer,:default => 0
    add_column :governments, :contributors_count, :integer,:default => 0
    add_column :governments, :partners_count, :integer, :default => 0
    add_column :governments, :official_user_priorities_count, :integer, :default => 0
    add_column :governments, :endorsements_count, :integer, :default => 0
    add_column :governments, :picture_id, :integer
    add_column :governments, :color_scheme_id, :integer, :default => 1
    add_column :governments, :mission, :string, :limit => 200
    add_column :governments, :prompt, :string, :limit => 100

    add_index :governments, :domain_name
    add_index :governments, :short_name
  
    Government.create(:status => "active", :short_name => "mygov", :layout => "basic", :name => "My Government", :tagline => "Where YOU set the priorities", :email => "youremail@youremailaddress.com", :target => "President", :is_facebook => 0, :admin_name => "Administrator", :admin_email => "adminemail@youremailaddress.com", :color_scheme_id => 1, :mission => "Make our country better", :prompt => "Our nation should:")
    ColorScheme.create(:input => "FFFFFF")
  end

  def self.down
  end
end
