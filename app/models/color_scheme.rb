class ColorScheme < ActiveRecord::Base

  named_scope :featured, :conditions => "is_featured = true"

  after_save :clear_cache
  
  has_attached_file :background_image, :storage => :s3, :s3_credentials => S3_CONFIG, 
    :path => ":class/:attachment/:id/:style.:extension", :bucket => ENV['DOMAIN']
  
  validates_attachment_size :background_image, :less_than => 5.megabytes
  validates_attachment_content_type :background_image, :content_type => ['image/jpeg', 'image/png', 'image/gif']  
  
  def clear_cache
    Rails.cache.delete('views/color_scheme/'+id.to_s)
    return true
  end
  
  def ColorScheme.not_colors
    ['id','updated_at','fonts','background_tiled','created_at','is_featured','background_image_file_name', 'background_image_content_type', 'background_image_file_size', 'background_image_updated_at']
  end
  
  def ColorScheme.theme_colors
    ['background', 'link', 'main', 'text', 'box', 'box_text', 'comments', 'comments_text', 'footer', 'footer_text', 'heading', 'sub_heading', 'nav_background', 'nav_text', 'nav_selected_background', 'nav_selected_text', 'nav_hover_background', 'nav_hover_text', 'action_button', 'action_button_border']
  end

  def unique_colors
    colors = []
    for column in ColorScheme.column_names
      colors << self[column].upcase if ColorScheme.theme_colors.include?(column) and not ['000000','FFFFFF'].include?(self[column].upcase)
    end
    colors.uniq
  end
  
end
