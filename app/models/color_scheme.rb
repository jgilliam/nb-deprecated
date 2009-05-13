class ColorScheme < ActiveRecord::Base

  after_save :clear_cache
  
  def clear_cache
    Rails.cache.delete('views/color_scheme/'+id.to_s)
    return true
  end

  def unique_colors
    colors = []
    for column in ColorScheme.column_names
      colors << self[column].upcase if not ColorScheme.not_colors.include?(column) and not ['000000','FFFFFF'].include?(self[column].upcase)
    end
    colors.uniq.sort {|x,y| Color::RGB.from_html(y).brightness <=> Color::RGB.from_html(x).brightness}
  end
  
  def adjust_brightness(percent)
    for column in ColorScheme.column_names
      if not ColorScheme.not_colors.include?(column)
        self[column] = Color::RGB.from_html(self[column]).adjust_brightness(percent).html[1..6]
      end
    end
  end

  def adjust_hue(percent)
    for column in ColorScheme.column_names
      if not ColorScheme.not_colors.include?(column)
        self[column] = Color::RGB.from_html(self[column]).adjust_hue(percent).html[1..6]
      end
    end
  end
  
  def adjust_saturation(percent)
    for column in ColorScheme.column_names
      if not ColorScheme.not_colors.include?(column)
        self[column] = Color::RGB.from_html(self[column]).adjust_saturation(percent).html[1..6]
      end
    end
  end  
  
  def darken_by(percent)
    for column in ColorScheme.column_names
      if not ColorScheme.not_colors.include?(column)
        self[column] = Color::RGB.from_html(self[column]).darken_by(percent).html[1..6]
      end
    end
  end
  
  def lighten_by(percent)
    for column in ColorScheme.column_names
      if not ColorScheme.not_colors.include?(column)
        self[column] = Color::RGB.from_html(self[column]).lighten_by(percent).html[1..6]
      end
    end
  end    

  def ColorScheme.not_colors
    ['id','updated_at','fonts','background_tiled','created_at','is_featured','background_picture_id']
  end

end
