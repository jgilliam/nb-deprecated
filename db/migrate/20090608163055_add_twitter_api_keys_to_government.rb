class AddTwitterApiKeysToGovernment < ActiveRecord::Migration
  def self.up
    add_column :governments, :twitter_key, :string, :limit => 46
    add_column :governments, :twitter_secret_key, :string, :limit => 46
  end

  def self.down
  end
end
