class Branch < ActiveRecord::Base

  extend ActiveSupport::Memoizable

  has_many :users, :dependent => :nullify
  has_many :endorsements, :class_name => "BranchEndorsement", :dependent => :destroy
  has_many :endorsement_rankings, :through => :endorsements, :source => :rankings
  has_many :endorsement_charts, :through => :endorsements, :source => :charts
  has_many :user_rankings, :class_name => "BranchUserRanking", :dependent => :destroy
  has_many :user_charts, :class_name => "BranchUserChart", :dependent => :destroy
  
  named_scope :by_users_count, :order => "branches.users_count desc"
  named_scope :with_endorsements, :conditions => "endorsements_count > 0"

  validates_presence_of :name
  validates_length_of :name, :within => 2..20

  after_create :check_if_default_branch_exists
  after_create :expire_cache
  after_destroy :expire_cache
  
  def expire_cache
    Branch.expire_cache
  end
  
  def Branch.expire_cache
    Rails.cache.delete(Government.current.short_name + '-Branch.by_users_count.all')
  end
  
  def check_if_default_branch_exists
    Government.current.update_attribute(:default_branch_id, self.id) unless Government.current.is_branches?
  end
  
  def update_counts
    self.users_count = users.active.count
    self.endorsements_count = endorsements.count
  end
  
  def priority_volume(limit=30)
    pc = BranchPriorityChart.find_by_sql(["SELECT sum(branch_priority_charts.volume_count) as volume_count
    from branch_priority_charts
    where branch_id = ?
    group by date_year, date_month, date_day
    order by date_year desc, date_month desc, date_day desc
    limit ?",id,limit])
    pc.collect{|c| c.volume_count.to_i}.reverse
  end  

  def user_ids
    users.active.find(:all, :select => "id").collect{|u|u.id} 
  end
  memoize :user_ids
  
  def Branch.all_cached
    @current_branches ||= Rails.cache.fetch(Government.current.short_name + '-Branch.by_users_count.all') { Branch.by_users_count.all }
  end
  
end
