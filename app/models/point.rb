class Point < ActiveRecord::Base

  named_scope :published, :conditions => "points.status = 'published'"
  named_scope :by_helpfulness, :order => "points.score desc"
  named_scope :by_endorser_helpfulness, :conditions => "points.endorser_score > 0", :order => "points.endorser_score desc"
  named_scope :by_neutral_helpfulness, :conditions => "points.neutral_score > 0", :order => "points.neutral_score desc"    
  named_scope :by_opposer_helpfulness, :conditions => "points.opposer_score > 0", :order => "points.opposer_score desc"
  named_scope :up, :conditions => "points.endorser_score > 0"
  named_scope :neutral, :conditions => "points.neutral_score > 0"
  named_scope :down, :conditions => "points.opposer_score > 0"    
  named_scope :by_recently_created, :order => "points.created_at desc"
  named_scope :by_recently_updated, :order => "points.updated_at desc"  
  named_scope :revised, :conditions => "revisions_count > 1"

  belongs_to :user
  belongs_to :priority
  belongs_to :other_priority, :class_name => "Priority"
  belongs_to :revision # the current revision
  
  has_many :revisions, :dependent => :destroy
  has_many :activities, :dependent => :destroy, :order => "activities.created_at desc"
  
  has_many :author_users, :through => :revisions, :select => "distinct users.*", :source => :user, :class_name => "User"
  
  has_many :point_qualities, :order => "created_at desc", :dependent => :destroy
  has_many :helpfuls, :class_name => "PointQuality", :conditions => "value = 1", :order => "created_at desc"
  has_many :unhelpfuls, :class_name => "PointQuality", :conditions => "value = 0", :order => "created_at desc"
  
  has_many :capitals, :as => :capitalizable, :dependent => :nullify
  
  define_index do
    set_property :field_weights => {:name => 10, :content => 5, :priority => 3, :link => 3}
    indexes :name
    indexes :content
    indexes :sphinx_index    
    indexes priority.name, :as => :priority
    indexes other_priority.name, :as => :link    
    where "points.status in ('published','draft')"
  end

  liquid_methods :id, :user, :text
  
  cattr_reader :per_page
  @@per_page = 15  
  
  def to_param
    "#{id}-#{name.gsub(/[^a-z0-9]+/i, '-').downcase}"
  end  
  
  after_destroy :delete_point_quality_activities
  before_destroy :remove_counts  
  
  validates_length_of :name, :within => 3..60
  validates_uniqueness_of :name  
  validates_length_of :content, :maximum => 500, :allow_blank => true, :allow_nil => true
  
  # docs: http://www.practicalecommerce.com/blogs/post/122-Rails-Acts-As-State-Machine-Plugin
  acts_as_state_machine :initial => :published, :column => :status
  
  state :draft
  state :published, :enter => :do_publish
  state :deleted, :enter => :do_delete
  state :buried, :enter => :do_bury
  
  event :publish do
    transitions :from => [:draft], :to => :published
  end
  
  event :delete do
    transitions :from => [:draft, :published,:buried], :to => :deleted
  end

  event :undelete do
    transitions :from => :deleted, :to => :published, :guard => Proc.new {|p| !p.published_at.blank? }
    transitions :from => :deleted, :to => :draft 
  end
  
  event :bury do
    transitions :from => [:draft, :published, :deleted], :to => :buried
  end
  
  event :unbury do
    transitions :from => :buried, :to => :published, :guard => Proc.new {|p| !p.published_at.blank? }
    transitions :from => :buried, :to => :draft     
  end  

  def do_publish
    self.published_at = Time.now
    add_counts
    priority.save_with_validation(false)    
  end
  
  def do_delete
    remove_counts
    capital_earned = capitals.sum(:amount)
    if capital_earned != 0
      self.capitals << CapitalPointHelpfulDeleted.new(:recipient => user, :amount => (capital_earned*-1)) 
    end    
    priority.save_with_validation(false)
    for r in revisions
      r.delete!
    end
  end
  
  def do_bury
    remove_counts
    priority.save_with_validation(false)    
  end
  
  def add_counts
    priority.up_points_count += 1 if is_up?
    priority.down_points_count += 1 if is_down?
    priority.neutral_points_count += 1 if is_neutral?        
    priority.points_count += 1
    user.increment!(:points_count)    
  end
  
  def remove_counts
    priority.up_points_count -= 1 if is_up?
    priority.down_points_count -= 1 if is_down?
    priority.neutral_points_count -= 1 if is_neutral?        
    priority.points_count -= 1
    user.decrement!(:points_count)        
  end
  
  def delete_point_quality_activities
    qs = Activity.find(:all, :conditions => ["point_id = ? and type in ('ActivityPointHelpfulDelete','ActivityPointUnhelpfulDelete')",self.id])
    for q in qs
      q.destroy
    end
  end

  def name_with_type
    return name unless is_down?
    "[opposed] " + name
  end

  def text
    s = name_with_type
    s += "\r\nIn support of " + other_priority.name if has_other_priority?
    s += "\r\n" + content
    s += "\r\nSource: " + website_link if has_website?
    return s
  end

  def authors
    revisions.count(:group => :user, :order => "count_all desc")
  end
  
  def editors
    revisions.count(:group => :user, :conditions => ["revisions.user_id <> ?", user_id], :order => "count_all desc")
  end  
  
  def is_up?
    value > 0
  end
  
  def is_down?
    value < 0
  end
  
  def is_neutral?
    value == 0
  end
  
  def is_deleted?
    status == 'deleted'
  end
  
  def calculate_score
    self.score = 0
    self.endorser_score = 0
    self.opposer_score = 0
    self.neutral_score = 0
    for q in point_qualities
      if q.is_helpful?
        vote = q.user.quality_factor
      else
        vote = -q.user.quality_factor
      end
      self.score += vote
      if q.is_endorser?
        self.endorser_score += vote
      elsif q.is_opposer?
        self.opposer_score += vote        
      else
        self.neutral_score += vote
      end
    end
  end
  
  def opposers_helpful?
    opposer_score > 0
  end
  
  def endorsers_helpful?
    endorser_score > 0    
  end
  
  def neutrals_helpful?
    neutral_score > 0    
  end  

  def everyone_helpful?
    score > 0    
  end
  
  def helpful_endorsers_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalPointHelpfulEndorsers'")
  end

  def helpful_opposers_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalPointHelpfulOpposers'")
  end
  
  def helpful_undeclareds_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalPointHelpfulUndeclareds'")
  end  
  
  def helpful_everyone_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalPointHelpfulEveryone'")
  end  

  def priority_name
    priority.name if priority
  end
  
  def priority_name=(n)
    self.priority = Priority.find_by_name(n) unless n.blank?
  end
  
  def other_priority_name
    other_priority.name if other_priority
  end
  
  def other_priority_name=(n)
    self.other_priority = Priority.find_by_name(n) unless n.blank?
  end

  def has_other_priority?
    attribute_present?("other_priority_id")
  end
  
  def website_link
    return nil if self.website.nil?
    wu = website
    wu = 'http://' + wu if wu[0..3] != 'http'
    return wu    
  end  
  
  def has_website?
    attribute_present?("website")
  end
  
  def show_url
    Government.current.homepage_url + 'points/' + to_param
  end  
  
  auto_html_for(:content) do
    redcloth
    youtube(:width => 330, :height => 210)
    vimeo(:width => 330, :height => 180)
    link(:rel => "nofollow")
  end  
  
end
