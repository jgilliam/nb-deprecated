class Government < ActiveRecord::Base

  extend ActiveSupport::Memoizable

  named_scope :active, :conditions => "status = 'active'"
  named_scope :unsearchable, :conditions => "is_searchable = 0"
  
  belongs_to :official_user, :class_name => "User"
  belongs_to :color_scheme
  belongs_to :picture
  belongs_to :buddy_icon, :class_name => "Picture"
  belongs_to :fav_icon, :class_name => "Picture"
  
  validates_presence_of     :name
  validates_length_of       :name, :within => 3..60

  validates_presence_of     :short_name
  validates_uniqueness_of   :short_name, :case_sensitive => false
  ReservedShortnames = %w[admin blog dev ftp mail pop pop3 imap smtp stage stats status www jim jgilliam gilliam feedback facebook builder nationbuilder misc]
  validates_exclusion_of    :short_name, :in => ReservedShortnames, :message => 'is already taken'  

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
  
  liquid_methods :short_name, :domain_name, :name, :tagline, :name_with_tagline, :email, :official_user_id, :official_user_short_name,:official_user_priorities_count, :has_official?, :official_user_name, :target, :is_tags, :is_facebook?, :is_legislators?, :admin_name, :admin_email, :tags_name, :briefing_name, :currency_name, :currency_short_name, :priorities_count, :points_count, :documents_count, :users_count, :contributors_count, :partners_count, :endorsements_count, :logo, :logo_small, :logo_tiny, :logo_large, :logo_dimensions, :picture_id, :base_url, :mission, :tags_name_plural

  after_save :clear_cache
  before_save :last_minute_checks
  
  def last_minute_checks
    self.homepage = 'top' if not self.is_tags? and self.homepage == 'index'
  end
  
  def clear_cache
    if NB_CONFIG["multiple_government_mode"]
      Rails.cache.delete('government-'+domain_name)
    else
      Rails.cache.delete('government')
    end
    return true
  end
  
  def switch_db
    if attribute_present?("db_name") and NB_CONFIG['multiple_government_mode']
      config = Rails::Configuration.new
      new_spec = config.database_configuration[RAILS_ENV].clone
      new_spec["database"] =  db_name
      ActiveRecord::Base.establish_connection(new_spec)
    end
    if self.is_facebook?
      ENV['FACEBOOK_API_KEY'] = self.facebook_api_key
      ENV['FACEBOOK_SECRET_KEY'] = self.facebook_secret_key
    end
    Government.current = self
  end
  
  def switch_db_back
    ENV['FACEBOOK_API_KEY'] = DB_CONFIG[RAILS_ENV]['facebook_api_key'] 
    ENV['FACEBOOK_SECRET_KEY'] = DB_CONFIG[RAILS_ENV]['facebook_secret_key']
    config = Rails::Configuration.new
    ActiveRecord::Base.establish_connection(config.database_configuration[RAILS_ENV]) 
  end

  def self.current  
    Thread.current[:government]  
  end  
  
  def self.current=(government)  
    raise(ArgumentError,"Invalid government. Expected an object of class 'Government', got #{government.inspect}") unless government.is_a?(Government)
    Thread.current[:government] = government
  end

  def is_custom_domain?
    return false unless NB_CONFIG['multiple_government_mode']
    return false unless attribute_present?("domain_name")
    !domain_name.include?(NB_CONFIG['multiple_government_base_url'])
  end  
  
  def base_url
    if NB_CONFIG['multiple_government_mode']
      return domain_name if attribute_present?("domain_name")
      return short_name + '.' + NB_CONFIG['multiple_government_base_url']
    else
      return domain_name
    end
  end
  
  def nb_url
    return short_name + '.' + NB_CONFIG['multiple_government_base_url']
  end
  
  # we use misc.nationbuilder.com for third party APIs on all *.nationbuilder.com governments
  # so they don't have to each create their own API keys.
  # it's hacky and lame, but requiring admins to get their own API keys is lamer.
  def misc_url
    return base_url if is_custom_domain?
    'misc.' + NB_CONFIG['multiple_government_base_url']
  end

  def name_with_tagline
    return name unless attribute_present?("tagline")
    name + ": " + tagline
  end
  
  def update_counts
    switch_db if NB_CONFIG["multiple_government_mode"]
    self.users_count = User.active.count
    self.priorities_count = Priority.published.count
    self.endorsements_count = Endorsement.active_and_inactive.count
    self.partners_count = Partner.active.count
    self.points_count = Point.published.count
    self.documents_count = Document.published.count
    self.contributors_count = User.active.at_least_one_endorsement.contributed.count
    self.official_user_priorities_count = official_user.endorsements_count if has_official?
    switch_db_back if NB_CONFIG["multiple_government_mode"]
    save_with_validation(false)
  end  
  
  def has_official?
    attribute_present?("official_user_id")
  end
  
  def official_user_name
    official_user.name if official_user
  end
  
  def official_user_name=(n)
    self.official_user = User.find_by_login(n) unless n.blank?
  end  
  
  def has_search_index?
    return true unless NB_CONFIG['multiple_government_mode']
    is_searchable?
  end
  
  def has_google_analytics?
    attribute_present?("google_analytics_code")
  end
  
  def has_fav_icon?
    attribute_present?("fav_icon_id")
  end
  
  def has_buddy_icon?
    attribute_present?("buddy_icon_id")
  end
  
  def logo
    return nil unless has_picture?
    '<div class="logo"><a href="/"><img src="/pictures/' + Government.current.short_name + '/get/' + picture_id.to_s + '" border="0"></a></div>'
  end
  
  def fav_icon_url
    if has_fav_icon?
      "/pictures/" + Government.current.short_name + "/icon_16/" + fav_icon_id.to_s
    else
      "/favicon.png"
    end
  end
  
  def buddy_icon_24_url
    if has_buddy_icon?
      "/pictures/" + Government.current.short_name + "/icon_24/" + buddy_icon_id.to_s
    else
      "/images/buddy_icon_24.png"
    end
  end  
  
  def buddy_icon_48_url
    if has_buddy_icon?
      "/pictures/" + Government.current.short_name + "/icon_48/" + buddy_icon_id.to_s
    else
      "/images/buddy_icon_48.png"
    end
  end  
  
  def buddy_icon_96_url
    if has_buddy_icon?
      "/pictures/" + Government.current.short_name + "/icon_96/" + buddy_icon_id.to_s
    else
      "/images/buddy_icon_96.png"
    end
  end  
  
  def logo_url
    "/pictures/" + Government.current.short_name + "/get/" + picture_id.to_s
  end
  
  def logo_dimensions
    return nil unless picture
    picture.width.to_s + 'x' + picture.height.to_s
  end
  
  def logo_large
    return nil unless has_picture?
    '<div class="logo_small"><a href="/"><img src="/pictures/' + Government.current.short_name + '/get_450/' + picture_id.to_s + '" border="0"></a></div>'
  end  
  
  def logo_small
    return nil unless has_picture?
    '<div class="logo_small"><a href="/"><img src="/pictures/' + Government.current.short_name + '/logo/' + picture_id.to_s + '" border="0"></a></div>'
  end
  
  def logo_tiny
    return nil unless has_picture?
    '<div class="logo_tiny"><a href="/"><img src="/pictures/' + Government.current.short_name + '/get_18_high/' + picture_id.to_s + '" border="0"></a></div>'
  end

  def has_picture?
    attribute_present?("picture_id")
  end
  
  def tags_name_plural
    tags_name.pluralize
  end

end
