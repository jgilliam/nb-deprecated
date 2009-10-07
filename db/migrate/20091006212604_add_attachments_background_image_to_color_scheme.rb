class AddAttachmentsBackgroundImageToColorScheme < ActiveRecord::Migration
  def self.up
    add_column :color_schemes, :background_image_file_name, :string
    add_column :color_schemes, :background_image_content_type, :string
    add_column :color_schemes, :background_image_file_size, :integer
    add_column :color_schemes, :background_image_updated_at, :datetime
    remove_column :color_schemes, :background_picture_id
  end

  def self.down
    remove_column :color_schemes, :background_image_file_name
    remove_column :color_schemes, :background_image_content_type
    remove_column :color_schemes, :background_image_file_size
    remove_column :color_schemes, :background_image_updated_at
  end
end
