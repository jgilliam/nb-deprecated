class Tag < ActiveRecord::Base

  extend ActiveSupport::Memoizable

  named_scope :by_endorsers_count, :order => "(tags.up_endorsers_count+tag.down_endorsers_count) desc"

  named_scope :alphabetical, :order => "tags.name asc"
  named_scope :more_than_three_priorities, :conditions => "tags.priorities_count > 3"
  
  named_scope :most_priorities, :conditions => "tags.priorities_count > 0", :order => "tags.priorities_count desc"
  named_scope :most_webpages, :conditions => "tags.webpages_count > 0", :order => "tags.webpages_count desc"  
  named_scope :most_feeds, :conditions => "tags.feeds_count > 0", :order => "tags.feeds_count desc"   

  has_many :taggings
  has_many :priorities, :through => :taggings, :source => :priority, :conditions => "taggings.taggable_type = 'Priority'"
  has_many :webpages, :through => :taggings, :source => :webpage, :conditions => "taggings.taggable_type = 'Webpage'"
  has_many :feeds, :through => :taggings, :source => :feed, :conditions => "taggings.taggable_type = 'Feed'"
                            
  belongs_to :top_priority, :class_name => "Priority", :foreign_key => "top_priority_id"
  belongs_to :rising_priority, :class_name => "Priority", :foreign_key => "rising_priority_id"
  belongs_to :controversial_priority, :class_name => "Priority", :foreign_key => "controversial_priority_id"  
  belongs_to :obama_priority, :class_name => "Priority", :foreign_key => "obama_priority_id"    
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  cattr_reader :per_page
  @@per_page = 15  
  
  # LIKE is used for cross-database case-insensitivity
  def self.find_or_create_with_like_by_name(name)
    find(:first, :conditions => ["name LIKE ?", name]) || create(:name => name)
  end
  
  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end
  
  def to_s
    name
  end
  
  def endorsements_count
    up_endorsers_count+down_endorsers_count
  end
  
  def count
    read_attribute(:count).to_i
  end
  
  def has_top_priority?
    attribute_present?("top_priority_id")
  end
  
  def rising_7days_count
    priorities.published.rising_7days.count
  end
  
  def flat_7days_count
    priorities.published.flat_7days.count
  end
  
  def falling_7days_count
    priorities.published.falling_7days.count
  end    
  
  def rising_7days_percent
    priorities.published.rising_7days.count.to_f/priorities_count.to_f
  end  
  
  def flat_7days_percent
    priorities.published.flat_7days.count.to_f/priorities_count.to_f
  end
  
  def falling_7days_percent
    priorities.published.falling_7days.count.to_f/priorities_count.to_f
  end    
  
  def rising_30days_count
    priorities.published.rising_30days.count
  end
  
  def flat_30days_count
    priorities.published.flat_30days.count
  end
  
  def falling_30days_count
    priorities.published.falling_30days.count
  end    
  
  def rising_24hr_count
    priorities.published.rising_24hr.count
  end
  
  def flat_24hr_count
    priorities.published.flat_24hr.count
  end
  
  def falling_24hr_count
    priorities.published.falling_24hr.count
  end  
  
  def subscribers
    User.find_by_sql(["
    select distinct users.*
    from users, endorsements, taggings
    where 
    endorsements.priority_id = taggings.taggable_id
    and taggings.tag_id = ?
    and taggings.taggable_type = 'Priority'
    and endorsements.status = 'active'
    and endorsements.user_id = users.id
    and users.is_newsletter_subscribed = 1
    and users.status in ('active','pending')",id])
  end
  
  def endorsers
    User.find_by_sql(["
    select distinct users.*
    from users, endorsements, taggings
    where 
    endorsements.priority_id = taggings.taggable_id
    and taggings.tag_id = ?
    and taggings.taggable_type = 'Priority'
    and endorsements.status = 'active'
    and endorsements.value = 1
    and endorsements.user_id = users.id
    and users.status in ('active','pending')",id])
  end  
  
  def opposers
    User.find_by_sql(["
    select distinct users.*
    from users, endorsements, taggings
    where 
    endorsements.priority_id = taggings.taggable_id
    and taggings.tag_id = ?
    and taggings.taggable_type = 'Priority'
    and endorsements.status = 'active'
    and endorsements.value = -1
    and endorsements.user_id = users.id
    and users.status in ('active','pending')",id])
  end  
  memoize :subscribers, :endorsers, :opposers
    
end
