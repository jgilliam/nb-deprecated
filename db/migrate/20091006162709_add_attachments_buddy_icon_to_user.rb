class AddAttachmentsBuddyIconToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :buddy_icon_file_name, :string
    add_column :users, :buddy_icon_content_type, :string, :limit => 30
    add_column :users, :buddy_icon_file_size, :integer
    add_column :users, :buddy_icon_updated_at, :datetime
  end

  def self.down
    remove_column :users, :buddy_icon_file_name
    remove_column :users, :buddy_icon_content_type
    remove_column :users, :buddy_icon_file_size
    remove_column :users, :buddy_icon_updated_at
  end
end
