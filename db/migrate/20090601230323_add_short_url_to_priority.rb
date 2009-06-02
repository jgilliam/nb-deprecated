class AddShortUrlToPriority < ActiveRecord::Migration
  def self.up
    add_column :priorities, :short_url, :string, :limit => 20
  end

  def self.down
  end
end
