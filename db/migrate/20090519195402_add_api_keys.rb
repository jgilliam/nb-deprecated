class AddApiKeys < ActiveRecord::Migration
  def self.up
    add_column :governments, :facebook_api_key, :string, :limit => 32
    add_column :governments, :facebook_secret_key, :string, :limit => 32
    add_column :governments, :windows_appid, :string, :limit => 32
    add_column :governments, :windows_secret_key, :string, :limit => 32
    add_column :governments, :yahoo_appid, :string, :limit => 40
    add_column :governments, :yahoo_secret_key, :string, :limit => 32    
  end

  def self.down
  end
end