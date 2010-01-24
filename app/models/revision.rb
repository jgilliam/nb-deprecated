class Revision < ActiveRecord::Base

  named_scope :published, :conditions => "revisions.status = 'published'"
  named_scope :by_recently_created, :order => "revisions.created_at desc"  

  belongs_to :point  
  belongs_to :user
  belongs_to :other_priority, :class_name => "Priority"
    
  has_many :activities
  has_many :notifications, :as => :notifiable, :dependent => :destroy
      
  # this is actually just supposed to be 500, but bumping it to 510 because the javascript counter doesn't include carriage returns in the count, whereas this does.
  validates_length_of :content, :maximum => 516, :allow_blank => true, :allow_nil => true, :too_long => I18n.t("points.new.errors.content_maximum")
  
  liquid_methods :id, :user, :url, :text
  
  # docs: http://www.practicalecommerce.com/blogs/post/122-Rails-Acts-As-State-Machine-Plugin
  acts_as_state_machine :initial => :draft, :column => :status
  
  state :draft
  state :archived, :enter => :do_archive
  state :published, :enter => :do_publish
  state :deleted, :enter => :do_delete
  
  event :publish do
    transitions :from => [:draft, :archived], :to => :published
  end

  event :archive do
    transitions :from => :published, :to => :archived
  end
  
  event :delete do
    transitions :from => [:published, :archived], :to => :deleted
  end

  event :undelete do
    transitions :from => :deleted, :to => :published, :guard => Proc.new {|p| !p.published_at.blank? }
    transitions :from => :deleted, :to => :archived 
  end
  
  before_save :truncate_user_agent
  def truncate_user_agent
    self.user_agent = self.user_agent[0..149] # some user agents are longer than 150 chars!
  end
  
  def do_publish
    self.published_at = Time.now
    self.auto_html_prepare
    begin
      Timeout::timeout(5) do   #times out after 5 seconds
        self.content_diff = HTMLDiff.diff(RedCloth.new(point.content).to_html,RedCloth.new(self.content).to_html)
      end
    rescue Timeout::Error
    end    
    point.revisions_count += 1    
    changed = false
    if point.revisions_count == 1
      ActivityPointNew.create(:user => user, :priority => point.priority, :point => point, :revision => self)
    else
      if point.content != self.content # they changed content
        changed = true
        ActivityPointRevisionContent.create(:user => user, :priority => point.priority, :point => point, :revision => self)
      end
      if point.website != self.website
        changed = true
        ActivityPointRevisionWebsite.create(:user => user, :priority => point.priority, :point => point, :revision => self)
      end
      if point.name != self.name
        changed = true
        ActivityPointRevisionName.create(:user => user, :priority => point.priority, :point => point, :revision => self)
      end
      if point.other_priority_id != self.other_priority_id
        changed = true
        ActivityPointRevisionOtherPriority.create(:user => user, :priority => point.priority, :point => point, :revision => self)
      end
      if point.value != self.value
        changed = true
        if self.is_up?
          ActivityPointRevisionSupportive.create(:user => user, :priority => point.priority, :point => point, :revision => self)
        elsif self.is_neutral?
          ActivityPointRevisionNeutral.create(:user => user, :priority => point.priority, :point => point, :revision => self)
        elsif self.is_down?
          ActivityPointRevisionOpposition.create(:user => user, :priority => point.priority, :point => point, :revision => self)
        end
      end      
    end    
    if changed
      for a in point.author_users
        if a.id != self.user_id
          notifications << NotificationPointRevision.new(:sender => self.user, :recipient => a)    
        end
      end
    end    
    point.content = self.content
    point.website = self.website
    point.revision_id = self.id
    point.value = self.value
    point.name = self.name
    point.other_priority = self.other_priority
    point.author_sentence = point.user.login
    point.author_sentence += ", edited by " + point.editors.collect{|a| a[0].login}.to_sentence if point.editors.size > 0
    point.published_at = Time.now
    point.save_with_validation(false)
    user.increment!(:point_revisions_count)    
  end
  
  def do_archive
    self.published_at = nil
  end
  
  def do_delete
    point.decrement!(:revisions_count)
    user.decrement!(:point_revisions_count)    
  end
  
  def is_up?
    value > 0
  end
  
  def is_down?
    value < 0
  end
  
  def is_neutral?
    value == 0
  end

  def priority_name
    priority.name if priority
  end
  
  def priority_name=(n)
    self.priority = Priority.find_by_name(n) unless n.blank?
  end
  
  def other_priority_name
    other_priority.name if other_priority
  end
  
  def other_priority_name=(n)
    self.other_priority = Priority.find_by_name(n) unless n.blank?
  end  
  
  def has_other_priority?
    attribute_present?("other_priority_id")
  end
  
  def text
    s = point.name
    s += " [opposed]" if is_down?
    s += " [neutral]" if is_neutral?    
    s += "\r\nIn support of " + point.other_priority.name if point.has_other_priority?
    s += "\r\n" + content
    s += "\r\nSource: " + website_link if has_website?
    return s
  end  
  
  def website_link
    return nil if self.website.nil?
    wu = website
    wu = 'http://' + wu if wu[0..3] != 'http'
    return wu    
  end  
  
  def has_website?
    attribute_present?("website")
  end  
  
  def request=(request)
    self.ip_address = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
  end
  
  def Revision.create_from_point(point_id, request)
    p = Point.find(point_id)
    r = Revision.new
    r.point = p
    r.user = p.user
    r.value = p.value
    r.name = p.name
    r.content = p.content
    r.content_diff = p.content
    r.website = p.website    
    r.request = request
    r.save_with_validation(false)
    r.publish!
  end
  
  def url
    'http://' + Government.current.base_url + '/points/' + point_id.to_s + '/revisions/' + id.to_s + '?utm_source=points_changed&utm_medium=email'
  end  
  
  auto_html_for(:content) do
    redcloth
    youtube(:width => 330, :height => 210)
    vimeo(:width => 330, :height => 180)
    link(:rel => "nofollow")
  end  
  
end
