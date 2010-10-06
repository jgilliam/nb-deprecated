class Webpage < ActiveRecord::Base

  named_scope :published, :conditions => "webpages.status = 'published'"
  named_scope :newest, :order => "webpages.created_at desc"

  belongs_to :user
  belongs_to :feed
  
  acts_as_taggable_on :issues
  
  acts_as_state_machine :initial => :published, :column => :status
  
  state :draft
  state :published
  state :deleted
  
  event :publish do
    transitions :from => :draft, :to => :published
  end
  
  event :delete do
    transitions :from => [:published, :draft], :to => :deleted
  end
  
  event :undelete do
    transitions :from => :deleted, :to => :published, :guard => Proc.new {|p| !p.published_at.blank? }
    transitions :from => :delete, :to => :draft 
  end
  
  validates_format_of :url, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
  validates_length_of :title, :within => 3..100, :allow_blank => true
  validates_length_of :description, :within => 1..255, :allow_blank => true  

  before_create :crawl  # crawl it right before creating it.
  before_save :set_domain

  def set_domain
    host = URI.parse(self.url).host.split('.')
    self.domain = host[host.length-2] + '.' + host[host.length-1]
    return self.domain
  end
  
  def crawl
    # don't bother doing this if there's already a title
    # don't want to overwrite a user supplied title
    return if attribute_present?("title")
    
    @response = ''
    
    # open-uri RDoc: http://stdlib.rubyonrails.org/libdoc/open-uri/rdoc/index.html
    begin
      Timeout::timeout(5) do   #times out after 5 seconds
        open(self.url,"User-Agent" => "White House 2",
                  "From" => Government.current.admin_email,
                  "Referer" => "http://#{Government.current.base_url}/") do |f|
              self.content_type = f.content_type
              self.charset = f.charset
              self.content_encoding = f.content_encoding
            # Save the response body
            @response = f.read
        end
      end
    rescue Timeout::Error
      errors.add("url","Cannot connect to that webpage.")
      errors.on("url")
    end      
    #Rdoc: http://code.whytheluckystiff.net/hpricot/
    doc = Hpricot(@response)
    
    #pull the title out if there isn't already one
    if not attribute_present?("title")
      (doc/"head/title").each do |title|
        self.title = title.inner_html.gsub("\r"," ").gsub("\n"," ").split(" ").join(" ")
      end
    end
    
    # find the description in the meta field if there isnt already a description
    #if not attribute_present?("description")    
    #  (doc/"head/meta").each do |meta|
    #    self.description = meta.attributes['content'] if meta.attributes['name'] and meta.attributes['name'].downcase == 'description'
    #  end
    #end
    
    # if couldn't find a description, try to get some text from the page
    #if not attribute_present?("description")
    #  doc.search("script").remove
    #  doc.search("link").remove
    #  doc.search("meta").remove
    #  doc.search("style").remove
    #  self.description = (doc/"body").inner_text.gsub("\r"," ").gsub("\n"," ").split(" ").join(" ")[0..150]
    #end
    
    if not attribute_present?("title")
      # use the host name as the default title i guess
      self.title = URI.parse(self.url).host
    end
    self.crawled_at = Time.now
  end
  
end
