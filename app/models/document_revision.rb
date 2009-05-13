class DocumentRevision < ActiveRecord::Base

  named_scope :published, :conditions => "document_revisions.status = 'published'"
  named_scope :by_recently_created, :order => "document_revisions.created_at desc"  

  belongs_to :document  
  belongs_to :user

  has_many :activities
  has_many :notifications, :as => :notifiable, :dependent => :destroy
  
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
  
  liquid_methods :text, :id, :url, :user
  
  before_save :update_word_count
  
  def do_publish
    self.published_at = Time.now
    self.auto_html_prepare
    begin
      Timeout::timeout(5) do   #times out after 5 seconds
        self.content_diff = HTMLDiff.diff(RedCloth.new(document.content).to_html,RedCloth.new(self.content).to_html)
      end
    rescue Timeout::Error
    end    
    document.revisions_count += 1    
    changed = false
    if document.revisions_count == 1
      ActivityDocumentNew.create(:user => user, :priority => document.priority, :document => document, :document_revision => self)
    else
      if document.content != self.content # they changed content
        changed = true
        ActivityDocumentRevisionContent.create(:user => user, :priority => document.priority, :document => document, :document_revision => self)
      end
      if document.name != self.name 
        changed = true
        ActivityDocumentRevisionName.create(:user => user, :priority => document.priority, :document => document, :document_revision => self)
      end
      if document.value != self.value and document.priority
        changed = true
        if self.is_up?
          ActivityDocumentRevisionSupportive.create(:user => user, :priority => document.priority, :document => document, :document_revision => self)
        elsif self.is_neutral?
          ActivityDocumentRevisionNeutral.create(:user => user, :priority => document.priority, :document => document, :document_revision => self)
        elsif self.is_down?
          ActivityDocumentRevisionOpposition.create(:user => user, :priority => document.priority, :document => document, :document_revision => self)
        end
      end      
    end    
    if changed
      sent = []
      for a in document.author_users
        if a.id != self.user_id
          notifications << NotificationDocumentRevision.new(:sender => self.user, :recipient => a)    
          sent << a.id
        end 
      end
      if document.research_task
        if document.research_task.requester and document.research_task.requester_id != self.user_id and not sent.include?("document.research_task.requester_id")
          # send a notification to the person who requested the research to begin with
          notifications << NotificationDocumentRevision.new(:sender => self.user, :recipient => document.research_task.requester)
        elsif document.research_task.attribute_present?("requester_email")
          # they aren't a member, send them an email instead
          UserMailer.deliver_new_document_revision_to_requester(self.user,document.research_task.requester_name,document.research_task.requester_email,self)
        end
      end
    end    
    document.content = self.content
    document.revision_id = self.id
    document.name = self.name
    document.value = self.value
    document.author_sentence = document.user.login
    document.author_sentence += ", edited by " + document.editors.collect{|a| a[0].login}.to_sentence if document.editors.size > 0
    document.published_at = Time.now
    document.save_with_validation(false)
    user.increment!(:document_revisions_count)
  end
  
  def do_archive
    self.published_at = nil
  end
  
  def do_delete
    document.decrement!(:revisions_count)
    user.decrement!(:document_revisions_count)    
  end
  
  def update_word_count
    self.word_count = self.content.split(' ').length
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

  def text
    s = document.name
    s += " [opposed]" if is_down?
    s += " [neutral]" if is_neutral? and has_priority?
    s += "\r\n" + content
    return s
  end  
  
  def has_priority?
    attribute_present?("priority_id")
  end
  
  def request=(request)
    self.ip_address = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
  end
  
  def DocumentRevision.create_from_document(document_id, request)
    p = Document.find(document_id)
    r = DocumentRevision.new
    r.document = p
    r.user = p.user
    r.value = p.value
    r.name = p.name
    r.content = p.content
    r.content_diff = p.content
    r.request = request
    r.save_with_validation(false)
    r.publish!
  end
  
  def url
    'http://' + Government.current.base_url + '/documents/' + document_id.to_s + '/revisions/' + id.to_s + '?utm_source=documents_changed&utm_medium=email'
  end

  auto_html_for(:content) do
    redcloth
    youtube(:width => 460, :height => 285)
    vimeo(:width => 460, :height => 260)
    link(:rel => "nofollow")
  end

end
