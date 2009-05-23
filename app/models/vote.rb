class Vote < ActiveRecord::Base
  
  named_scope :deleted, :conditions => "votes.status = 'deleted'"
  named_scope :not_deleted, :conditions => "votes.status <> 'deleted'"
  named_scope :active, :conditions => "votes.status = 'active'", :include => {:change => :priority}, :order => "priorities.endorsements_count desc"
  named_scope :pending, :conditions => "votes.status in ('active','sent')", :include => {:change => :priority}, :order => "votes.created_at desc"

  belongs_to :user
  belongs_to :change
  has_many :activities  
  has_many :notifications, :as => :notifiable, :dependent => :destroy
  
  before_create :make_code
  after_create :add_notification
  
  acts_as_state_machine :initial => :active, :column => :status
  
  state :active
  state :approved, :enter => :do_approve
  state :implicit_approved, :enter => :do_implicit_approve
  state :declined, :enter => :do_decline
  state :implicit_declined
  state :inactive  
  state :deleted
  
  event :approve do
    transitions :from => [:active], :to => :approved
  end

  event :decline do
    transitions :from => [:active], :to => :declined
  end    
  
  event :implicit_approve do
    transitions :from => [:active], :to => :implicit_approved
  end

  event :implicit_decline do
    transitions :from => [:active], :to => :implicit_declined
  end  
  
  event :deactivate do
    transitions :from => [:sent], :to => :inactive
  end
  
  event :delete do
    transitions :from => [:active, :inactive, :approved, :declined], :to => :deleted
  end  
  
  def do_approve
    self.voted_at = Time.now
    change.decrement!("no_votes") if self.status == 'declined'
    change.increment!("yes_votes")
    old_endorsement = replace
  end
  
  def do_implicit_approve
    old_endorsement = replace(true)
  end  
  
  def do_decline
    self.voted_at = Time.now
    change.decrement!("yes_votes") if self.status == 'approved'
    change.increment!("no_votes")
    ActivityPriorityAcquisitionProposalNo.create(:user => user, :change => change, :vote => self, :priority => change.priority)
  end
  
  def replace(implicit=false)
    old_endorsement = change.priority.endorsements.find_by_user_id(user.id)
    return true if not old_endorsement
    # do they already have the new endorsement?
    new_endorsement = change.new_priority.endorsements.find_by_user_id(user.id)
    if not new_endorsement
      if change.is_flip?
        if old_endorsement.is_up?
          new_endorsement = change.new_priority.oppose(user)
          if implicit
            ActivityOppositionFlippedImplicit.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.position, :vote => self)
          else
            ActivityOppositionFlipped.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.posiion, :vote => self)
          end
        else
          new_endorsement = change.new_priority.endorse(user)
          if implicit
            ActivityEndorsementFlippedImplicit.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.position, :vote => self)
          else
            ActivityEndorsementFlipped.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.position, :vote => self)
          end
        end        
      else
        if old_endorsement.is_up?
          new_endorsement = change.new_priority.endorse(user)
          if implicit
            ActivityEndorsementReplacedImplicit.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.position, :vote => self)
          else
            ActivityEndorsementReplaced.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.position, :vote => self)
          end
        else
          new_endorsement = change.new_priority.oppose(user)
          if implicit
            ActivityOppositionReplacedImplicit.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.position, :vote => self)
          else
            ActivityOppositionReplaced.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.position, :vote => self)          
          end
        end
      end
    else
      if change.is_flip?
        if old_endorsement.is_down?
          new_endorsement = change.new_priority.endorse(user)
          if implicit
            ActivityEndorsementFlippedImplicit.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.position, :vote => self)
          else
            ActivityEndorsementFlipped.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.position, :vote => self)          
          end
        else
          new_endorsement = change.new_priority.oppose(user)
          if implicit
            ActivityOppositionFlippedImplicit.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.position, :vote => self)            
          else
            ActivityOppositionFlipped.create(:user => user, :change => change, :priority => change.priority, :position => new_endorsement.position, :vote => self)
          end
        end
      end
    end
    if old_endorsement and new_endorsement and old_endorsement.attribute_present?("position") and new_endorsement.attribute_present?("position") and old_endorsement.position < new_endorsement.position
      new_endorsement.insert_at(old_endorsement.position) 
    end
    old_endorsement.replace!
    return old_endorsement    
  end
  
  def is_up?
    value == 1
  end
  
  def is_down?
    value == -1
  end

  private
  def add_notification
    notifications << NotificationChangeVote.new(:sender => self.change.user, :recipient => self.user)
  end
  
  def make_code
    self.code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
  
end
