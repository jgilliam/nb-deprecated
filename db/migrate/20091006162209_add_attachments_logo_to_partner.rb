class AddAttachmentsLogoToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :logo_file_name, :string
    add_column :partners, :logo_content_type, :string, :limit => 30
    add_column :partners, :logo_file_size, :integer
    add_column :partners, :logo_updated_at, :datetime
  end

  def self.down
    remove_column :partners, :logo_file_name
    remove_column :partners, :logo_content_type
    remove_column :partners, :logo_file_size
    remove_column :partners, :logo_updated_at
  end
end
