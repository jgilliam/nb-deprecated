class AddBuddyIconAndFavIconToGovernment < ActiveRecord::Migration
  def self.up
    add_column :governments, :buddy_icon_id, :integer
    add_column :governments, :fav_icon_id, :integer
  end

  def self.down
  end
end
