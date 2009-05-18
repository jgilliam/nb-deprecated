class Message < ActiveRecord::Base

  named_scope :active, :conditions => "messages.status <> 'deleted'"
  named_scope :sent, :conditions => "messages.status in('sent','read')"
  named_scope :read, :conditions => "messages.status = 'read'"
  named_scope :unread, :conditions => "messages.status = 'sent'"
  named_scope :draft, :conditions => "messages.status = 'draft'"
  
  named_scope :by_recently_sent, :order => "messages.sent_at desc"
  named_scope :by_oldest_sent, :order => "messages.sent_at asc"  
  named_scope :by_unread, :order => "messages.status desc, messages.sent_at desc"

  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  
  has_many :notifications, :as => :notifiable, :dependent => :destroy  
  
  validates_presence_of :content
  
  liquid_methods :content, :created_at
  
  acts_as_state_machine :initial => :draft, :column => :status
  
  state :draft
  state :sent, :enter => :do_send
  state :read, :enter => :do_read  
  state :deleted, :enter => :do_delete
  
  event :send do
    transitions :from => [:draft], :to => :sent
  end
  
  event :read do
    transitions :from => [:sent, :draft], :to => :read
  end

  event :delete do
    transitions :from => [:sent, :draft, :read], :to => :deleted
  end

  event :undelete do
    transitions :from => :deleted, :to => :read, :guard => Proc.new {|p| !p.read_at.blank? }    
    transitions :from => :deleted, :to => :sent, :guard => Proc.new {|p| !p.sent_at.blank? }
    transitions :from => :deleted, :to => :draft 
  end
  
  def do_send
    self.deleted_at = nil  
    if not Following.find_by_user_id_and_other_user_id_and_value(self.recipient_id,self.sender_id,-1) and self.sent_at.blank?
      self.notifications << NotificationMessage.new(:sender => self.sender, :recipient => self.recipient)
    end
    self.sent_at = Time.now
  end
  
  def do_read
    self.deleted_at = nil
    self.read_at = Time.now
    for n in self.notifications
      n.read!
      Rails.cache.delete("views/" + Government.current.short_name + "-" + n[:type].downcase + "-" + n.id.to_s)
    end
  end
  
  def do_delete
    self.deleted_at = Time.now
    for n in self.notifications
      n.delete!
    end    
  end
  
  cattr_reader :per_page
  @@per_page = 25
  
  def unread?
    self.status == 'sent'
  end
  
  def recipient_name
    recipient.name if recipient
  end
  
  def recipient_name=(n)
    self.recipient = User.find_by_login(n) unless n.blank?
  end  
  
  auto_html_for(:content) do
    redcloth
    youtube(:width => 330, :height => 210)
    vimeo(:width => 330, :height => 180)
    link(:rel => "nofollow")
  end  
  
end
