class AddAttachmentsLogoToGovernment < ActiveRecord::Migration
  def self.up
    add_column :governments, :logo_file_name, :string
    add_column :governments, :logo_content_type, :string, :limit => 30
    add_column :governments, :logo_file_size, :integer
    add_column :governments, :logo_updated_at, :datetime
    remove_column :webpages, :picture_id
  end

  def self.down
    remove_column :governments, :logo_file_name
    remove_column :governments, :logo_content_type
    remove_column :governments, :logo_file_size
    remove_column :governments, :logo_updated_at
  end
end
