class BranchEndorsement < ActiveRecord::Base

  belongs_to :branch
  belongs_to :priority
  has_many :charts, :class_name => "BranchEndorsementChart", :dependent => :destroy
  has_many :rankings, :class_name => "BranchEndorsementRanking", :dependent => :destroy
  
  named_scope :top_rank, :order => "branch_endorsements.position asc"
  named_scope :not_top_rank, :conditions => "branch_endorsements.position > 25"
  named_scope :rising, :conditions => "branch_endorsements.position_7days_change > 0", :order => "(branch_endorsements.position_7days_change/branch_endorsements.position) desc"
  named_scope :falling, :conditions => "branch_endorsements.position_7days_change < 0", :order => "(branch_endorsements.position_7days_change/branch_endorsements.position) asc"

  named_scope :rising_7days, :conditions => "branch_endorsements.position_7days_change > 0"
  named_scope :flat_7days, :conditions => "branch_endorsements.position_7days_change = 0"
  named_scope :falling_7days, :conditions => "branch_endorsements.position_7days_change < 0"
  named_scope :rising_30days, :conditions => "branch_endorsements.position_30days_change > 0"
  named_scope :flat_30days, :conditions => "branch_endorsements.position_30days_change = 0"
  named_scope :falling_30days, :conditions => "branch_endorsements.position_30days_change < 0"
  named_scope :rising_24hr, :conditions => "branch_endorsements.position_24hr_change > 0"
  named_scope :flat_24hr, :conditions => "branch_endorsements.position_24hr_change = 0"
  named_scope :falling_24hr, :conditions => "branch_endorsements.position_24hr_change < 0"
  
  named_scope :random, :order => "rand()"
  named_scope :newest, :order => "branch_endorsements.created_at desc"
  named_scope :controversial, :conditions => "(branch_endorsements.up_endorsements_count/branch_endorsements.down_endorsements_count) between 0.5 and 2", :order => "(branch_endorsements.endorsements_count - abs(branch_endorsements.up_endorsements_count-branch_endorsements.down_endorsements_count)) desc"
  
  acts_as_list :scope => 'branch_endorsements.branch_id = #{branch_id}'
  
  cattr_reader :per_page
  @@per_page = 25
  
  after_create :add_counts
  after_destroy :remove_counts
  
  def add_counts
    self.branch.increment!(:endorsements_count)
  end
  
  def remove_counts
    self.branch.decrement!(:endorsements_count)
  end
  
  def is_new?
    created_at > Time.now-(86400*7) or position_7days == 0    
  end
  
  def update_counts
    self.up_endorsements_count = Endorsement.count(:conditions => ["priority_id = ? and user_id in (?) and value = 1",self.priority_id, branch.user_ids])
    self.down_endorsements_count = Endorsement.count(:conditions => ["priority_id = ? and user_id in (?) and value = -1",self.priority_id, branch.user_ids])
    self.endorsements_count = self.up_endorsements_count+self.down_endorsements_count
  end
  
  def is_much_more_important?
    return false if position == 0
    return false unless is_more_important?
    return true if (position_difference/position) >= 0.1
  end
  
  def is_slightly_more_important?
    return false if position == 0
    return false unless is_more_important?    
    return true if (position_difference/position) < 0.1
  end  
  
  def is_more_important?
    return false if position == 0
    position < priority.position
  end
  
  def position_difference
    return 0 if position == 0 or priority.position == 0
    (position-priority.position).abs
  end
  
  def is_less_important?
    return false if position == 0
    position > priority.position
  end

  def is_slightly_less_important?
    return false if position == 0  
    return false unless is_less_important? 
    return true if (position_difference/priority.position) < 0.1
  end
  
  def is_much_less_important?
    return false if position == 0
    return false unless is_less_important?
    return true if (position_difference/priority.position) >= 0.1
  end

end
