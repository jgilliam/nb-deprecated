class Invitation < ActiveRecord::Base
  
  named_scope :has_sender, :conditions => "sender_id is not null"
  
  belongs_to :user
  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  belongs_to :partner
  belongs_to :recipient, :class_name => "User", :foreign_key => "to_id"

  has_many :activities
  
  # docs: http://www.vaporbase.com/postings/stateful_authentication
  acts_as_state_machine :initial => :unsent, :column => :status
  
  state :unsent
  state :sent, :enter => :do_send
  state :accepted, :enter => :do_accept
  
  event :send do
    transitions :from => :unsent, :to => :sent
  end
  
  event :accept do
    transitions :from => [:sent, :unsent], :to => :accepted
  end  
  
  validates_presence_of     :to_email, :unless => :has_facebook?
  validates_presence_of     :from_name
  #validates_presence_of    :to_name
  validates_length_of       :from_name,    :minimum => 3
  validates_length_of       :to_email,    :minimum => 3
  validates_format_of       :to_email, :with => /^[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+$/x
  
  def has_facebook?
    attribute_present?("facebook_uid")
  end
  
end
