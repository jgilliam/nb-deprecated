class Comment < ActiveRecord::Base

  named_scope :published, :conditions => "comments.status = 'published'"
  named_scope :published_and_abusive, :conditions => "comments.status in ('published','abusive')"
  named_scope :deleted, :conditions => "comments.status = 'deleted'"
  named_scope :flagged, :conditions => "flags_count > 0"
    
  named_scope :last_three_days, :conditions => "comments.created_at > date_add(now(), INTERVAL -3 DAY)"
  named_scope :by_recently_created, :order => "comments.created_at desc"  
  named_scope :by_first_created, :order => "comments.created_at asc"  
    
  belongs_to :user
  belongs_to :activity
  
  has_many :notifications, :as => :notifiable, :dependent => :destroy
  
  validates_presence_of :content
  
  liquid_methods :id, :activity_id, :content, :user, :activity, :url
  
  # docs: http://www.vaporbase.com/postings/stateful_authentication
  acts_as_state_machine :initial => :published, :column => :status
  
  state :published, :enter => :do_publish
  state :deleted, :enter => :do_delete  
  state :abusive, :enter => :do_abusive
  
  event :delete do
    transitions :from => :published, :to => :deleted
  end
  
  event :undelete do
    transitions :from => :deleted, :to => :published
  end  
  
  event :abusive do
    transitions :from => :published, :to => :abusive
  end
  
  def do_publish
    self.activity.increment!("comments_count")
    self.user.increment!("comments_count")
    for u in activity.commenters
      if u.id != self.user_id and not Following.find_by_user_id_and_other_user_id_and_value(u.id,self.user_id,-1)
        if u.id != self.activity.user_id
          notifications << NotificationComment.new(:sender => self.user, :recipient => u)
        elsif self.activity.class == ActivityBulletinProfileNew and u.id == self.activity.user_id
          notifications << NotificationComment.new(:sender => self.user, :recipient => u)
        end
      end
    end
    if self.activity.comments_count > 1 # there might be other comment participants
      for a in self.activity.activities
        a.update_attribute(:updated_at, Time.now)
      end
    else # this is the first comment, so need to update the discussions_count as appropriate
      if self.activity.has_point? and self.activity.point
        self.activity.point.increment!(:discussions_count)
      end
      if self.activity.has_document? and self.activity.document
        self.activity.document.increment!(:discussions_count)
      end
      if self.activity.has_priority? and self.activity.priority
        self.activity.priority.increment!(:discussions_count)
        if self.activity.priority.attribute_present?("cached_issue_list")
          for issue in self.activity.priority.issues
            issue.increment!(:discussions_count)
          end
        end        
      end
    end
    return if self.activity.user_id == self.user_id or (self.activity.class == ActivityBulletinProfileNew and self.activity.other_user_id = self.user_id and self.activity.comments_count < 2) # they are commenting on their own activity
    if exists = ActivityCommentParticipant.find_by_user_id_and_activity_id(self.user_id,self.activity_id)
      exists.increment!("comments_count")
    else
      ActivityCommentParticipant.create(:user => self.user, :activity => self.activity, :comments_count => 1, :is_user_only => 1 )
    end
    unless Following.find_by_user_id_and_other_user_id_and_value(self.activity.user_id,self.user_id,-1)
      notifications << NotificationComment.new(:sender => self.user, :recipient => self.activity.user)      
    end
  end
  
  def do_delete    
    self.activity.decrement!("comments_count")    
    self.user.decrement!("comments_count")
    if self.activity.comments_count == 0
      if self.activity.has_point? and self.activity.point
        self.activity.point.decrement!(:discussions_count)
      end
      if self.activity.has_document? and self.activity.document
        self.activity.document.decrement!(:discussions_count)
      end
      if self.activity.has_priority? and self.activity.priority
        self.activity.priority.decrement!(:discussions_count)
        if self.activity.priority.attribute_present?("cached_issue_list")
          for issue in self.activity.priority.issues
            issue.decrement!(:discussions_count)
          end
        end
      end      
    end
    return if self.activity.user_id == self.user_id    
    exists = ActivityCommentParticipant.find_by_user_id_and_activity_id(self.user_id,self.id)
    if exists and exists.comments_count > 1
      exists.decrement!(:comments_count)
    elsif exists
      exists.delete!
    end
    for n in notifications
      n.delete!
    end
  end
  
  def do_abusive
    if self.user.warnings_count == 0 # this is their first warning, get a warning message
      notifications << NotificationWarning1.new(:recipient => self.user)
    elsif self.user.warnings_count == 1 # 2nd warning, lose 10% of pc
      notifications << NotificationWarning2.new(:recipient => self.user)
      capital_lost = (self.user.capitals_count*0.1).to_i
      capital_lost = 1 if capital_lost == 0
      ActivityCapitalWarning.create(:user => self.user, :capital => CapitalWarning.create(:recipient => self.user, :amount => -capital_lost))
    elsif self.user.warnings_count == 2 # third warning, on probation, lose 30% of pc
      notifications << NotificationWarning3.new(:recipient => self.user)      
      capital_lost = (self.user.capitals_count*0.3).to_i
      capital_lost = 3 if capital_lost < 3
      ActivityCapitalWarning.create(:user => self.user, :capital => CapitalWarning.create(:recipient => self.user, :amount => -capital_lost))
      self.user.probation!
    elsif self.user.warnings_count == 3 # fourth warning, suspended
      self.user.suspended!
    end
    self.update_attribute(:flags_count, 0)
    self.user.increment!("warnings_count")
  end
  
  def request=(request)
    self.ip_address = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.referrer = request.env['HTTP_REFERER']
  end
  
  def parent_name 
    if activity.has_point?
      user.login + ' commented on ' + activity.point.name
    elsif activity.has_priority?
      user.login + ' commented on ' + activity.priority.name
    else
      user.login + ' posted a bulletin'
    end    
  end
  
  def flag_by_user(user)
    self.increment!(:flags_count)
    for r in User.active.admins
      notifications << NotificationCommentFlagged.new(:sender => user, :recipient => r)    
    end
  end
  
  def url
    'http://' + Government.current.base_url + '/activities/' + activity_id.to_s + '/comments#' + id.to_s + '?utm_source=comments&utm_medium=email'
  end
  
  auto_html_for(:content) do
    html_escape
    youtube(:width => 330, :height => 210)
    vimeo(:width => 330, :height => 180)
    #image
    link(:rel => "nofollow")
    simple_format_comment
  end
  
end
