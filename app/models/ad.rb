class Ad < ActiveRecord::Base

  named_scope :active, :conditions => "ads.status = 'active'"
  named_scope :inactive, :conditions => "ads.status in ('inactive','finished')"
  named_scope :finished, :conditions => "ads.status = 'finished'"
  named_scope :most_paid, :order => "ads.per_user_cost desc"
  named_scope :active_first, :order => "ads.status asc, ads.per_user_cost desc, ads.created_at desc"
  named_scope :by_recently_created, :order => "ads.created_at desc"
  
  belongs_to :user
  belongs_to :priority
  
  has_many :shown_ads, :dependent => :destroy
  has_many :activities

  acts_as_list :scope => 'status = \'active\''

  def validate
    if self.calculate_per_user_cost < 0.01
      errors.add("cost","per member must be more than 0.01" + Government.current.currency_short_name)
    elsif self.cost > user.capitals_count
      errors.add("cost","is more " + Government.current.currency_name.downcase + " than you have.")
    end    
    errors.on("cost")
    if priority.position < 26
      errors.add(:base, "You can not purchase ads for priorities in the top 25 already.")
    end
    if priority.is_buried?
      errors.add(:base, "You can not purchase ads for priorities that have been buried.")
    end    
  end
  
  validates_presence_of :show_ads_count
  validates_numericality_of :show_ads_count
  validates_presence_of :cost
  validates_numericality_of :cost
  validates_presence_of :content
  validates_length_of :content, :maximum => 90, :allow_nil => true, :allow_blank => true

  acts_as_state_machine :initial => :active, :column => :status
  
  state :inactive, :enter => :do_inactive
  state :active, :enter => :do_active
  state :finished, :enter => :do_finished
    
  event :start do
    transitions :from => [:finished, :inactive], :to => :active
  end

  event :finish do
    transitions :from => [:active, :inactive], :to => :finished
  end
  
  event :deactivate do
    transitions :from => [:active], :to => :inactive
  end  
  
  def do_finished
    self.finished_at = Time.now
    row = 0
    for a in Ad.active.most_paid.find(:all, :conditions => ["id <> ?",self.id])
      row += 1
      a.update_attribute(:position,row)
    end
  end
  
  def do_active
    row = 0
    for a in Ad.active.most_paid.all
      row += 1
      a.update_attribute(:position,row)
    end    
  end
  
  def do_inactive
    row = 0
    for a in Ad.active.most_paid.find(:all, :conditions => ["id <> ?",self.id])
      row += 1
      a.update_attribute(:position,row)
    end    
  end

  before_save :calculate_costs
  after_create :log_activity
  
  def calculate_costs
    self.per_user_cost = calculate_per_user_cost
    self.spent = self.shown_ads_count * self.per_user_cost
  end
  
  def calculate_per_user_cost
    return 0 if not self.attribute_present?("cost")
    return 0 if not self.attribute_present?("show_ads_count")    
    self.cost/self.show_ads_count.to_f
  end
  
  def log_activity
    user.increment(:ads_count)
    @activity = ActivityCapitalAdNew.create(:user => user, :priority => priority, :ad => self, :capital => CapitalAdNew.create(:sender => user, :amount => self.cost))
    if self.attribute_present?("content")
      @comment = @activity.comments.new
      @comment.content = content
      @comment.user = user
      if priority
        # if this is related to a priority, check to see if they endorse it
        e = priority.endorsements.active_and_inactive.find_by_user_id(user.id)
        @comment.is_endorser = true if e and e.is_up?
        @comment.is_opposer = true if e and e.is_down?
      end
      @comment.save_with_validation(false)
    end
  end

  def priority_name
    priority.name if priority
  end
  
  def priority_name=(n)
    self.priority = Priority.find_by_name(n) unless n.blank?
  end
  
  def no_response_count
    shown_ads_count - yes_count - no_count
  end
  
  def has_content?
    attribute_present?("content")
  end

  # u= user, v=value, r=request
  def vote(u,v,r)
    sa = shown_ads.find_by_user_id(u.id)
    if sa and sa.value != v
      if sa.value == 1 and v == -1
        self.decrement!(:yes_count)
        self.increment!(:no_count)
      elsif sa.value == -1 and v == 1
        self.decrement!(:no_count)
        self.increment!(:yes_count)       
      elsif sa.value == 0 and v == -1
        self.increment!(:no_count) 
      elsif sa.value == 0 and v == 1
        self.increment!(:yes_count)
      elsif sa.value == -1 and v == 0
        self.decrement!(:no_count)
      elsif sa.value == 1 and v == 0
        self.decrement!(:yes_count)
      end
      sa.value = v
      sa.request = r
      sa.save
    elsif not sa
      sa = shown_ads.create(:user => u, :value => v, :request => r)
    end
    if sa and sa.value == 1
      priority.endorse(u,r,nil,self.user)
      @activity = ActivityEndorsementNew.find_by_priority_id_and_user_id(@priority.id,u.id, :order => "created_at desc")
      @activity.update_attribute(:ad_id,self.id) if @activity
    elsif sa and sa.value == -1
      priority.oppose(u,r,nil,self.user)
      @activity = ActivityOppositionNew.find_by_priority_id_and_user_id(@priority.id,u.id, :order => "created_at desc")
      @activity.update_attribute(:ad_id,self.id) if @activity
    end
  end

  def self.find_active_cached
    Rails.cache.fetch('Ad.active.all') { active.most_paid.all }
  end
  
end
