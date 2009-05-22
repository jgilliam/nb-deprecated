class PicturesController < ApplicationController
  
  layout false
  caches_page :get, :get_600, :get_450, :get_18_high, :icon_180, :icon_140, :icon_96, :icon_48, :icon_24, :icon_16, :logo
  
  before_filter :get_picture

  require 'RMagick'

  def get # just returns the entire image, same as it was added to the database
    response.headers['Cache-Control'] = 'public'
    send_data @picture.data, :filename => @picture.name, :type => @picture.content_type, :disposition => "inline"
  end
  
  def get_600
    if @picture.attribute_present?("width") and @picture.width > 600
      @img = @img.change_geometry("600x") { |cols, rows, img| img.resize!(cols,rows) }
    end
    send_picture
  end  
  
  def get_450
    if @picture.attribute_present?("width") and @picture.width > 450
      @img = @img.change_geometry("450x") { |cols, rows, img| img.resize!(cols,rows) }
    end
    send_picture    
  end  
  
  def get_18_high
    if @picture.attribute_present?("width") and @picture.height > 18
      @img = @img.change_geometry("x18") { |cols, rows, img| img.resize!(cols,rows) }
    end
    send_picture    
  end  
  
  def icon_180
    if @picture.attribute_present?("width") and @picture.width > 200
      @img = @img.change_geometry("180x300") { |cols, rows, img| img.resize!(cols,rows) }
    end
    send_picture    
  end  
  
  def icon_140
    @img = @img.change_geometry("140x140") { |cols, rows, img| img.resize!(cols,rows) }
    send_picture
  end  

  def icon_96
    @img = @img.change_geometry("96x96") { |cols, rows, img| img.resize!(cols,rows) }
    send_picture
  end
  
  def logo
    if @picture.is_wide?
      @img = @img.change_geometry("150x100") { |cols, rows, img| img.resize!(cols,rows) }      
    else
      @img = @img.change_geometry("96x96") { |cols, rows, img| img.resize!(cols,rows) }
    end    
    send_picture
  end

  def icon_48
    @img = @img.change_geometry("48x48") { |cols, rows, img| img.resize!(cols,rows) }
    send_picture
  end

  def icon_24
    @img = @img.change_geometry("24x24") { |cols, rows, img| img.resize!(cols,rows) }
    send_picture
  end

  def icon_16
    @img = @img.change_geometry("16x16") { |cols, rows, img| img.resize!(cols,rows) }
    send_picture
  end

  private
  def get_picture
    @picture = Picture.find(params[:id])
    @img = Magick::Image.from_blob(@picture.data).first    
  end
  
  def send_picture
    response.headers['Cache-Control'] = 'public'
    send_data @img.to_blob, :filename => @picture.name, :type => @picture.content_type, :disposition => "inline"
  end
  
end
