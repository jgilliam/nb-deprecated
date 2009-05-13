class UserContact < ActiveRecord::Base

  named_scope :active, :conditions => "user_contacts.status <> 'deleted'"
  named_scope :tosend, :conditions => "user_contacts.status = 'tosend'"  

  named_scope :members, :conditions => "user_contacts.other_user_id is not null and users.status in ('active','pending')"
  named_scope :not_members, :conditions => "user_contacts.other_user_id is null"

  named_scope :invited, :conditions => "user_contacts.sent_at is not null or user_contacts.status = 'tosend'"
  named_scope :not_invited, :conditions => "user_contacts.sent_at is null and user_contacts.status <> 'tosend'"

  named_scope :following, :conditions => "user_contacts.following_id is not null"
  named_scope :not_following, :conditions => "user_contacts.following_id is null"

  named_scope :facebook, :conditions => "user_contacts.facebook_uid is not null"
  named_scope :not_facebook, :conditions => "user_contacts.facebook_uid is null"
  
  named_scope :recently_updated, :order => "user_contacts.updated_at desc"
  named_scope :recently_created, :order => "user_contacts.created_at desc"  
  
  belongs_to :user
  belongs_to :other_user, :class_name => "User"
  belongs_to :following

  # docs: http://www.vaporbase.com/postings/stateful_authentication
  acts_as_state_machine :initial => :unsent, :column => :status
  
  state :unsent
  state :tosend, :enter => :do_invite
  state :sent, :enter => :do_send
  state :accepted, :enter => :do_accept
  state :deleted, :enter => :do_delete
  
  event :invite do
    transitions :from => :unsent, :to => :tosend
  end
  
  event :send do
    transitions :from => :tosend, :to => :sent
  end
  
  event :accept do
    transitions :from => [:sent, :unsent, :tosend], :to => :accepted
  end  
  
  event :delete do
    transitions :from => [:sent, :unsent, :tosend, :accepted], :to => :deleted
  end  
  
  validates_presence_of     :email, :unless => :has_facebook?
  validates_length_of       :email, :minimum => 3, :unless => :has_facebook?
  validates_format_of       :email, :with => /^[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+$/x, :allow_nil => true, :allow_blank => true

  after_create :add_counts
  before_destroy :remove_counts

  def add_counts
    return if attribute_present?("following_id") # already in the followings_count
    if attribute_present?("other_user_id")
      user.increment!(:contacts_members_count)
    elsif not is_invited?
      user.increment!(:contacts_not_invited_count)
    elsif is_invited?
      user.increment!(:contacts_invited_count)
    end
    user.increment!(:contacts_count)
  end
  
  def remove_counts
    return if attribute_present?("following_id") # already in the followings_count
    if attribute_present?("other_user_id")
      user.decrement!(:contacts_members_count)
    elsif not is_invited?
      user.decrement!(:contacts_not_invited_count)
    elsif is_invited?
      user.decrement!(:contacts_invited_count)
    end
    user.decrement!(:contacts_count)
  end
  
  cattr_reader :per_page
  @@per_page = 25  
  
  def from_name
    if is_from_realname?
      return user.real_name
    else
      return user.login
    end
  end
  
  def has_facebook?
    attribute_present?("facebook_uid")
  end
  
  def has_email?
    attribute_present?("email")
  end  
  
  def is_sent?
    attribute_present?("sent_at")
  end  
  
  def is_invited?
    status == 'tosend' or attribute_present?("sent_at")
  end
  
  def is_accepted?
    attribute_present?("accepted_at")
  end  
  
  def do_invite
    # disabling invitation activity
    #ActivityInvitationNew.create(:user => user)
    user.contacts_invited_count += 1
    user.contacts_not_invited_count += -1
    user.save_with_validation(false)
  end
  
  def do_send
    return if attribute_present?("sent_at") # only send it once
    send_email
  end

  def send_email
    if has_email?
      UserMailer.deliver_invitation(user,from_name,name,email)      
    elsif has_facebook?
      # don't do anything on send if it's facebook, because it was sent through the facebook system already
    end    
    self.sent_at = Time.now    
  end
  
  def do_accept
    # can deliver an email notifying the person who invited them
    self.accepted_at = Time.now
    if has_email?
      self.other_user = User.find_by_email(email)
    elsif has_facebook?
      self.other_user = User.find_by_facebook_uid(facebook_uid)
    end
    if self.other_user.referral_id != self.user_id
      self.other_user.update_attribute(:referral_id,self.user_id)
      ActivityInvitationAccepted.create(:other_user => user, :user => self.other_user)
      ActivityUserRecruited.create(:user => user, :other_user => self.other_user, :is_user_only => true) 
      user.increment!(:referrals_count)
    end
    self.following = user.follow(self.other_user)
    user.decrement!(:contacts_invited_count)    
    self.other_user.notifications << NotificationInvitationAccepted.new(:sender => self.other_user, :recipient => user)
  end  
  
  def do_delete
    remove_counts
  end
  
end
