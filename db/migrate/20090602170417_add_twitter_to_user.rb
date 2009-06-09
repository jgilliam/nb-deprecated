class AddTwitterToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :twitter_id, :integer
    add_column :users, :twitter_token, :string, :limit => 64
    add_column :users, :twitter_secret, :string, :limit => 64
    add_index :users, :twitter_id
    remove_column :users, :youtube_login
    remove_column :users, :digg_login
  end

  def self.down
  end
end
