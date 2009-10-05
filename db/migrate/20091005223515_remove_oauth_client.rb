class RemoveOauthClient < ActiveRecord::Migration
  def self.up
    drop_table :oauth_nonces
    drop_table :oauth_tokens
  end

  def self.down
  end
end
