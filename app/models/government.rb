class Government < ActiveRecord::Base

  extend ActiveSupport::Memoizable
  require 'paperclip'
  
  named_scope :active, :conditions => "status = 'active'"
  named_scope :pending, :conditions => "status = 'pending'"
  named_scope :least_active, :conditions => "status = 'active'", :order => "users_count"
  named_scope :with_branches, :conditions => "default_branch_id is not null"
  named_scope :without_branches, :conditions => "default_branch_id is null"
  named_scope :facebook, :conditions => "is_facebook = true"
  named_scope :twitter, :conditions => "is_twitter = true"
  
  belongs_to :official_user, :class_name => "User"
  belongs_to :color_scheme
  
  belongs_to :picture
  
  has_attached_file :logo, :styles => { :icon_96 => "96x96#", :icon_140  => "140x140#", :icon_180 => "180x180#", :medium => "450x" }, 
    :storage => :s3, :s3_credentials => S3_CONFIG, 
    :path => ":class/:attachment/:id/:style.:extension"
  
  validates_attachment_size :logo, :less_than => 5.megabytes
  validates_attachment_content_type :logo, :content_type => ['image/jpeg', 'image/png', 'image/gif']
    
  belongs_to :buddy_icon_old, :class_name => "Picture"
  has_attached_file :buddy_icon, :styles => { :icon_24 => "24x24#", :icon_48  => "48x48#", :icon_96 => "96x96#" }, 
    :storage => :s3, :s3_credentials => S3_CONFIG, :default_url => "/images/buddy_:style.png",
    :path => ":class/:attachment/:id/:style.:extension"
    
  validates_attachment_size :buddy_icon, :less_than => 5.megabytes
  validates_attachment_content_type :buddy_icon, :content_type => ['image/jpeg', 'image/png', 'image/gif']    
      
  belongs_to :fav_icon_old, :class_name => "Picture"
  has_attached_file :fav_icon, :styles => { :icon_16 => "16x16#" }, 
    :storage => :s3, :s3_credentials => S3_CONFIG, :default_url => "/favicon.png",
    :path => ":class/:attachment/:id/:style.:extension"
  
  validates_attachment_size :fav_icon, :less_than => 5.megabytes
  validates_attachment_content_type :fav_icon, :content_type => ['image/jpeg', 'image/png', 'image/gif']  
  
  belongs_to :default_branch, :class_name => "Branch"
  
  validates_presence_of     :name
  validates_length_of       :name, :within => 3..60

  validates_presence_of     :short_name
  validates_uniqueness_of   :short_name, :case_sensitive => false
  ReservedShortnames = %w[admin blog dev ftp mail pop pop3 imap smtp stage stats status www jim jgilliam gilliam feedback facebook builder nationbuilder misc]
  validates_exclusion_of    :short_name, :in => ReservedShortnames, :message => 'is already taken'  
  validates_format_of       :short_name, :with => /^([a-z]|[a-z][a-z0-9]|[a-z]([a-z0-9]|\-[a-z0-9])*)$/

  validates_presence_of     :admin_name
  validates_length_of       :admin_name, :within => 3..60

  validates_presence_of     :admin_email
  validates_length_of       :admin_email, :within => 3..100, :allow_nil => true, :allow_blank => true
  validates_format_of       :admin_email, :with => /^[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+$/x

  validates_presence_of     :email
  validates_length_of       :email, :within => 3..100, :allow_nil => true, :allow_blank => true
  validates_format_of       :email, :with => /^[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+$/x

  validates_presence_of     :tags_name
  validates_length_of       :tags_name, :maximum => 20
  validates_presence_of     :briefing_name
  validates_length_of       :briefing_name, :maximum => 20
  validates_presence_of     :currency_name
  validates_length_of       :currency_name, :maximum => 30
  validates_presence_of     :currency_short_name
  validates_length_of       :currency_short_name, :maximum => 3
  
  validates_inclusion_of    :homepage, :in => Homepage::NAMES.collect{|n|n[0]}
  validates_inclusion_of    :tags_page, :in => Homepage::TAGS.collect{|n|n[0]}
  
  liquid_methods :short_name, :domain_name, :name, :tagline, :name_with_tagline, :email, :official_user_id, :official_user_short_name,:official_user_priorities_count, :has_official?, :official_user_name, :target, :is_tags, :has_facebook_enabled?, :has_twitter_enabled?, :is_legislators?, :admin_name, :admin_email, :tags_name, :briefing_name, :currency_name, :currency_short_name, :priorities_count, :points_count, :documents_count, :users_count, :contributors_count, :partners_count, :endorsements_count, :logo, :logo_small, :logo_tiny, :logo_large, :logo_dimensions, :picture_id, :base_url, :homepage_url, :mission, :tags_name_plural

  after_save :clear_cache
  before_save :last_minute_checks
  
  def last_minute_checks
    self.homepage = 'top' if not self.is_tags? and self.homepage == 'index'
  end
  
  def clear_cache
    Rails.cache.delete('government')
    return true
  end
  
  def self.current  
    Thread.current[:government]  
  end  
  
  def self.current=(government)  
    raise(ArgumentError,"Invalid government. Expected an object of class 'Government', got #{government.inspect}") unless government.is_a?(Government)
    Thread.current[:government] = government
  end
  
  def update_user_default_branch
    User.connection.execute("update users set branch_id = #{default_branch_id} where is_branch_chosen = false;")
    for branch in Branch.all
      branch.update_counts
      branch.save_with_validation(false)
    end
    Branch.expire_cache  
  end

  def base_url
    return ENV['DOMAIN']
  end
  
  def homepage_url
    'http://' + base_url + '/'
  end
  
  def name_with_tagline
    return name unless attribute_present?("tagline")
    name + ": " + tagline
  end
  
  def update_counts
    self.users_count = User.active.count
    self.priorities_count = Priority.published.count
    self.endorsements_count = Endorsement.active_and_inactive.count
    self.partners_count = Partner.active.count
    self.points_count = Point.published.count
    self.documents_count = Document.published.count
    self.contributors_count = User.active.at_least_one_endorsement.contributed.count
    self.official_user_priorities_count = official_user.endorsements_count if has_official?
    save_with_validation(false)
  end  
  
  def has_official?
    attribute_present?("official_user_id")
  end

  def is_branches?
    attribute_present?("default_branch_id")
  end
  
  def official_user_name
    official_user.name if official_user
  end
  
  def official_user_name=(n)
    self.official_user = User.find_by_login(n) unless n.blank?
  end  
  
  def has_google_analytics?
    attribute_present?("google_analytics_code")
  end
  
  def has_twitter_enabled?
    return false unless is_twitter?
    return true if attribute_present?("twitter_key") and attribute_present?("twitter_secret_key")
  end
  
  def has_facebook_enabled?
    return false unless is_facebook?
    return true if Facebooker.api_key
  end
  
  def has_windows_enabled?
    self.attribute_present?("windows_appid")
  end
  
  def has_yahoo_enabled?
    self.attribute_present?("yahoo_appid")
  end
  
  # this will go away when full migrated to paperclip
  def has_picture?
    attribute_present?("picture_id")
  end
  
  def has_fav_icon?
    attribute_present?("fav_icon_file_name")
  end
  
  def has_buddy_icon?
    attribute_present?("buddy_icon_file_name")
  end
  
  def has_logo?
    attribute_present?("logo_file_name")
  end
  
  def is_searchable?
    not ENV["WEBSOLR_URL"].nil?
  end

  def logo_large
    return nil unless has_logo?
    '<div class="logo_small"><a href="/"><img src="' + logo.url(:medium) + '" border="0"></a></div>'
  end  
  
  def logo_small
    return nil unless has_logo?
    '<div class="logo_small"><a href="/"><img src="' + logo.url(:icon_140) + '" border="0"></a></div>'
  end
  
  def tags_name_plural
    tags_name.pluralize
  end

end
