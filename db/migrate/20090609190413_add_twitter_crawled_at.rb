class AddTwitterCrawledAt < ActiveRecord::Migration
  def self.up
    add_column :users, :twitter_crawled_at, :datetime
  end

  def self.down
  end
end
