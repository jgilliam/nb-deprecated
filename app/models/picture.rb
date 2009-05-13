class Picture < ActiveRecord::Base
  
  require 'RMagick'
  
  has_one :owner, :class_name => "User", :foreign_key => "picture_id"
  has_many :activities  
  
  validates_format_of :content_type, :with => /^image/, :message => "--- you can only upload pictures"

  def picture=(picture_field)
    self.name = File.basename(picture_field.original_filename).gsub(/[^\w._-]/, '')
    self.content_type = picture_field.content_type.chomp
    self.data = picture_field.read
    img_big = Magick::Image.from_blob(self.data).first
    if not img_big.nil?
      if img_big.rows > 750 #need to shrink it
        new_img_big = img_big.change_geometry("720x1200") { |cols, rows, img| img.resize(cols, rows) }
        self.data = new_img_big.to_blob {self.quality = 75 }
        img_big = new_img_big
      end
      self.height = img_big.rows
      self.width = img_big.columns
    else # this isn't an image... send back some kind of error?
      errors.add("picture", "must be a 'gif' or 'jpeg' image")
      errors.on("picture")          
    end    
  end

  def file_data=(d)
    img_big = Magick::Image.from_blob(d).first
    if not img_big.nil?
      self.data = d
      if img_big.rows > 750 #need to shrink it
        new_img_big = img_big.change_geometry("720x1200") { |cols, rows, img| img.resize(cols, rows) }
        self.data = new_img_big.to_blob {self.quality = 75 }
        img_big = new_img_big
      end
      self.height = img_big.rows
      self.width = img_big.columns
    else # this isn't an image... send back some kind of error?
      errors.add("picture", "must be a 'gif' or 'jpeg' image")
      errors.on("picture")          
    end
  end
  
  def is_wide?
    return false unless attribute_present?("width")
    width*0.7 > height
  end
  
  def Picture.create_from_url(u)
    url = URI.parse(u)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.get(url.path)
    }
    pic = Picture.new
    pic.name = File.basename(url.path).gsub(/[^\w._-]/, '')
    pic.content_type = res.content_type
    pic.file_data = res.body
    pic.save
    return pic
  end  
  
end
