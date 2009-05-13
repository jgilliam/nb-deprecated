class Page < ActiveRecord::Base

  ReservedShortnames = %w[about faq privacy rules]
  
  validates_presence_of :short_name
  validates_exclusion_of :short_name, :in => ReservedShortnames, :message => 'is already taken'
  validates_uniqueness_of :short_name

  validates_presence_of :name
  
  before_save :check_link_name
  after_save :clear_cache
  
  def check_link_name
    self.link_name = self.short_name.humanize unless attribute_present?("link_name")
    self.short_name = self.short_name.parameterize.wrapped_string
  end
  
  def clear_cache
    Rails.cache.delete("views/" + Government.current.short_name + "-page-" + short_name)
    Rails.cache.delete("views/" + Government.current.short_name + "-pages")
    return true
  end
  
end
