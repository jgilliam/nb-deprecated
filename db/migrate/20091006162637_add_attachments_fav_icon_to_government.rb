class AddAttachmentsFavIconToGovernment < ActiveRecord::Migration
  def self.up
    add_column :governments, :fav_icon_file_name, :string
    add_column :governments, :fav_icon_content_type, :string, :limit => 30
    add_column :governments, :fav_icon_file_size, :integer
    add_column :governments, :fav_icon_updated_at, :datetime
  end

  def self.down
    remove_column :governments, :fav_icon_file_name
    remove_column :governments, :fav_icon_content_type
    remove_column :governments, :fav_icon_file_size
    remove_column :governments, :fav_icon_updated_at
  end
end
