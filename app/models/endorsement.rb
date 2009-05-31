class Endorsement < ActiveRecord::Base

  extend ActiveSupport::Memoizable
  
  named_scope :active, :conditions => "endorsements.status = 'active'"
  named_scope :deleted, :conditions => "endorsements.status = 'deleted'" 
  named_scope :suspended, :conditions => "endorsements.status = 'suspended'"
  named_scope :active_and_inactive, :conditions => "endorsements.status in ('active','inactive','finished')" 
  named_scope :opposing, :conditions => "endorsements.value < 0"
  named_scope :endorsing, :conditions => "endorsements.value > 0"
  named_scope :obama_endorsed, :conditions => "priorities.obama_value = 1", :include => :priority
  named_scope :not_obama, :conditions => "priorities.obama_value = 0", :include => :priority
  named_scope :obama_opposed, :conditions => "priorities.obama_value = -1", :include => :priority
  named_scope :not_obama_or_opposed, :conditions => "priorities.obama_value < 1", :include => :priority
  named_scope :finished, :conditions => "endorsements.status in ('inactive','finished') and priorities.status = 'inactive'", :include => :priority
  named_scope :top10, :order => "endorsements.position asc", :limit => 10
  
  named_scope :by_position, :order => "endorsements.position asc"
  named_scope :by_priority_position, :order => "priorities.position asc"
  named_scope :by_priority_lowest_position, :order => "priorities.position desc"  
  named_scope :by_recently_created, :order => "endorsements.created_at desc"
  named_scope :by_recently_updated, :order => "endorsements.updated_at desc"  
  
  belongs_to :partner
  belongs_to :user
  belongs_to :priority
  belongs_to :referral, :class_name => "User", :foreign_key => "referral_id"
  
  belongs_to :tagging
  has_many :notifications, :as => :notifiable, :dependent => :destroy
  has_many :top_endorsements, :class_name => "User", :foreign_key => "top_endorsement_id", :dependent => :nullify
  
  cattr_reader :per_page
  @@per_page = 25
  
  liquid_methods :value, :value_name, :id, :user, :priority  
  
  # docs: http://noobonrails.blogspot.com/2007/02/actsaslist-makes-lists-drop-dead-easy.html
  acts_as_list :scope => 'endorsements.user_id = #{user_id} AND status = \'active\''
  
  # docs: http://www.vaporbase.com/postings/stateful_authentication
  acts_as_state_machine :initial => :active, :column => :status
  
  state :active, :enter => :do_activate
  state :inactive
  state :finished, :enter => :do_finish
  state :deleted # deprecated, in favor of just flat out deleting them.  too many problems with aasm
  state :suspended, :enter => :do_suspension
  state :replaced, :enter => :do_replace
  
  event :activate do
    transitions :from => [:deleted, :suspended, :replaced], :to => :active
  end
  
  event :deactivate do
    transitions :from => [:active, :finished], :to => :inactive
  end  
  
  event :finish do
    transitions :from => [:active, :inactive], :to => :finished
  end
  
  event :undelete do
    transitions :from => [:deleted, :replaced], :to => :active
  end
  
  event :unsuspend do
    transitions :from => :suspended, :to => :active
  end
  
  event :suspend do
    transitions :from => :active, :to => :suspended
  end
  
  event :replace do
    transitions :from => [:deleted, :active], :to => :replaced
  end

  before_create :calculate_score
  after_save :check_for_top_priority
  after_save :check_obama
  before_destroy :remove
  after_destroy :check_for_top_priority
  
  # check to see if they've added a new #1 priority, and create the activity
  def check_for_top_priority
    if self.position == 1
      if self.id != user.top_endorsement_id
        user.top_endorsement = self
        user.save_with_validation(false)
        if self.is_up?
          ActivityPriority1.find_or_create_by_user_id_and_priority_id(user.id, self.priority_id)
        elsif self.is_down?
          ActivityPriority1Opposed.find_or_create_by_user_id_and_priority_id(user.id, self.priority_id)
        end
      end
    elsif user.top_endorsement_id.nil?
      e = user.endorsements.active.by_position.find(:all, :conditions => "position > 0", :limit => 1)[0]
      user.top_endorsement = e
      user.save_with_validation(false)
      if e.is_up?
        ActivityPriority1.find_or_create_by_user_id_and_priority_id(user.id, e.priority_id)
      elsif e.is_down?
        ActivityPriority1Opposed.find_or_create_by_user_id_and_priority_id(user.id, e.priority_id)
      end      
    end
  end
  
  def check_obama
    return unless user_id == Government.current.official_user_id
    priority.update_attribute(:obama_value,1) if is_up? and status == 'active'
    priority.update_attribute(:obama_value,-1) if is_down? and status == 'active'
    priority.update_attribute(:obama_value,0) if status == 'deleted'
  end
  
  def priority_name
    priority.name if priority
  end
  memoize :priority_name
  
  def priority_name=(n)
    self.priority = Priority.find_by_name(n) unless n.blank?
  end
  
  def calculate_score
    if position > 100  # this ignores any of a user's priorities below 100
      self.score = 0 
    else
      self.score = user.calculate_score*value*(101-position)
    end
  end
  
  def is_up?
    self.value > 0
  end
  
  def is_down?
    not self.is_up?
  end
  
  def is_active?
    status == 'active'
  end

  def is_replaced?
    status == 'replaced'
  end

  def value_name
    return 'endorsed' if is_up?
    return 'opposed' if is_down?
  end

  def flip_up
    return self if self.is_up?
    self.value = 1
  end
  
  def flip_down
    return self if self.is_down?
    self.value = -1
  end

  private
  
  def remove
    if self.status == 'active'
      if user_id == Government.current.official_user_id and priority.obama_value != 0
        priority.update_attribute(:obama_value,0)
      end
      delete_update_counts
      if self.is_up?
        ActivityEndorsementDelete.create(:user => user, :partner => partner, :priority => priority)
      else
        ActivityOppositionDelete.create(:user => user, :partner => partner, :priority => priority)
      end
    end
  end
  
  def do_finish
    remove_from_list
    notifications << NotificationPriorityFinished.new(:recipient => self.user)
  end  
  
  def do_replace
    delete_update_counts
  end
  
  def do_activate
    if self.is_up?
      ActivityEndorsementNew.create(:user => user, :partner => partner, :priority => priority, :position => self.position) 
    else
      ActivityOppositionNew.create(:user => user, :partner => partner, :priority => priority, :position => self.position)    
    end
    move_to_bottom
    add_update_counts
  end
  
  def do_suspension
    delete_update_counts
  end  
  
  def delete_update_counts
    priority.endorsements_count += -1
    if self.is_up?
      priority.up_endorsements_count += -1
    else
      priority.down_endorsements_count += -1
    end
    priority.save_with_validation(false)
    user.endorsements_count += -1
    if self.is_up?
      user.up_endorsements_count += -1
    else
      user.down_endorsements_count += -1
    end  
    user.save_with_validation(false)
    if Government.current.is_branches? and user.has_branch?
      be = priority.branch_endorsements.find_by_branch_id(user.branch_id)
      if be
        be.endorsements_count += -1
        if self.is_up?
          be.up_endorsements_count += -1
        else
          be.down_endorsements_count += -1
        end
        be.save_with_validation(false)        
      end
    end
  end
  
  def add_update_counts
    priority.endorsements_count += 1
    if self.is_up?
      priority.up_endorsements_count += 1
    else
      priority.down_endorsements_count += 1
    end
    priority.save_with_validation(false)
    user.endorsements_count += 1
    if self.is_up?
      user.up_endorsements_count += 1
    else
      user.down_endorsements_count += 1
    end  
    user.save_with_validation(false) 
    if Government.current.is_branches? and user.has_branch?
      be = priority.branch_endorsements.find_or_create_by_branch_id(user.branch_id)
      if be
        be.endorsements_count += 1
        if self.is_up?
          be.up_endorsements_count += 1
        else
          be.down_endorsements_count += 1
        end
        be.save_with_validation(false)
      end
    end    
  end  
  
end
