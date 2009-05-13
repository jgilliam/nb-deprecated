class Document < ActiveRecord::Base

  named_scope :published, :conditions => "documents.status = 'published'"
  named_scope :by_helpfulness, :order => "documents.score desc"
  named_scope :by_endorser_helpfulness, :conditions => "documents.endorser_score > 0", :order => "documents.endorser_score desc"
  named_scope :by_neutral_helpfulness, :conditions => "documents.neutral_score > 0", :order => "documents.neutral_score desc"    
  named_scope :by_opposer_helpfulness, :conditions => "documents.opposer_score > 0", :order => "documents.opposer_score desc"
  named_scope :up, :conditions => "documents.endorser_score > 0"
  named_scope :neutral, :conditions => "documents.neutral_score > 0"
  named_scope :down, :conditions => "documents.opposer_score > 0"  

  named_scope :by_recently_created, :order => "documents.created_at desc"
  named_scope :by_recently_updated, :order => "documents.updated_at desc"  
  named_scope :revised, :conditions => "revisions_count > 1"

  belongs_to :user
  belongs_to :priority
  belongs_to :revision, :class_name => "DocumentRevision", :foreign_key => "revision_id" # the current revision
  
  has_many :revisions, :class_name => "DocumentRevision", :dependent => :destroy
  has_many :activities, :dependent => :destroy, :order => "activities.created_at desc"
  
  has_many :author_users, :through => :revisions, :select => "distinct users.*", :source => :user, :class_name => "User"
  
  has_many :qualities, :class_name => "DocumentQuality", :order => "created_at desc", :dependent => :destroy
  has_many :helpfuls, :class_name => "DocumentQuality", :conditions => "value = 1", :order => "created_at desc"
  has_many :unhelpfuls, :class_name => "DocumentQuality", :conditions => "value = 0", :order => "created_at desc"
  
  has_many :capitals, :as => :capitalizable, :dependent => :nullify
  
  has_one :research_task

  liquid_methods :id, :text, :user
  
  define_index do
    set_property :field_weights => {:name => 10, :content => 5, :priority => 3}
    indexes :name
    indexes :content
    indexes :sphinx_index
    indexes priority.name, :as => :priority
    where "documents.status in ('published','draft')"
  end  
  
  cattr_reader :per_page
  @@per_page = 25
  
  def to_param
    "#{id}-#{name.gsub(/[^a-z0-9]+/i, '-').downcase}"
  end  
  
  after_destroy :delete_document_quality_activities
  before_destroy :remove_counts
  before_save :update_word_count
  
  validates_length_of :name, :within => 3..60
  validates_uniqueness_of :name  
  
  # docs: http://www.practicalecommerce.com/blogs/post/122-Rails-Acts-As-State-Machine-Plugin
  acts_as_state_machine :initial => :published, :column => :status
  
  state :draft
  state :published, :enter => :do_publish
  state :deleted, :enter => :do_delete
  state :buried, :enter => :do_bury
  
  event :publish do
    transitions :from => [:draft], :to => :published
  end
  
  event :delete do
    transitions :from => [:draft, :published,:buried], :to => :deleted
  end

  event :undelete do
    transitions :from => :deleted, :to => :published, :guard => Proc.new {|p| !p.published_at.blank? }
    transitions :from => :deleted, :to => :draft 
  end
  
  event :bury do
    transitions :from => [:draft, :published, :deleted], :to => :buried
  end
  
  event :unbury do
    transitions :from => :buried, :to => :published, :guard => Proc.new {|p| !p.published_at.blank? }
    transitions :from => :buried, :to => :draft     
  end  

  def update_word_count
    self.word_count = self.content.split(' ').length
  end

  def do_publish
    self.published_at = Time.now
    add_counts
    priority.save_with_validation(false) if priority
  end
  
  def do_delete
    remove_counts
    # look for any capital they may have earned on this document, and remove it
    capital_earned = capitals.sum(:amount)
    if capital_earned != 0
      self.capitals << CapitalDocumentHelpfulDeleted.new(:recipient => user, :amount => (capital_earned*-1))
    end
    priority.save_with_validation(false)
    for r in revisions
      r.delete!
    end
  end
  
  def do_bury
    remove_counts
    priority.save_with_validation(false) if priority
  end
  
  def add_counts
    if priority
      priority.up_documents_count += 1 if is_up?
      priority.down_documents_count += 1 if is_down?
      priority.neutral_documents_count += 1 if is_neutral?        
      priority.documents_count += 1
    end
    user.increment!(:documents_count)
  end
  
  def remove_counts
    if priority
      priority.up_documents_count -= 1 if is_up?
      priority.down_documents_count -= 1 if is_down?
      priority.neutral_documents_count -= 1 if is_neutral?        
      priority.documents_count -= 1
    end
    user.decrement!(:documents_count)    
  end
  
  def delete_document_quality_activities
    qs = Activity.find(:all, :conditions => ["document_id = ? and type in ('ActivityDocumentHelpfulDelete','ActivityDocumentUnhelpfulDelete')",self.id])
    for q in qs
      q.destroy
    end
  end

  def text
    s = name
    s += " [opposed]" if is_down?
    s += " [neutral]" if is_neutral? and has_priority?  
    s += "\r\n" + content
    return s
  end

  def has_priority?
    attribute_present?("priority_id")
  end

  def authors
    revisions.count(:group => :user, :order => "count_all desc")
  end
  
  def editors
    revisions.count(:group => :user, :conditions => ["document_revisions.user_id <> ?", user_id], :order => "count_all desc")
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
  
  def calculate_score
    self.score = 0
    self.endorser_score = 0
    self.opposer_score = 0
    self.neutral_score = 0
    for q in qualities
      if q.is_helpful?
        vote = q.user.quality_factor
      else
        vote = -q.user.quality_factor
      end
      self.score += vote
      if q.is_endorser?
        self.endorser_score += vote
      elsif q.is_opposer?
        self.opposer_score += vote        
      else
        self.neutral_score += vote
      end
    end
  end  
  
  def opposers_helpful?
    opposer_score > 0
  end
  
  def endorsers_helpful?
    endorser_score > 0    
  end
  
  def neutrals_helpful?
    neutral_score > 0    
  end  

  def everyone_helpful?
    score > 0    
  end
  
  def is_deleted?
    status == 'deleted'
  end
  
  def helpful_endorsers_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalDocumentHelpfulEndorsers'")
  end

  def helpful_opposers_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalDocumentHelpfulOpposers'")
  end
  
  def helpful_undeclareds_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalDocumentHelpfulUndeclareds'")
  end  
  
  def helpful_everyone_capital_spent
    capitals.sum(:amount, :conditions => "type = 'CapitalDocumentHelpfulEveryone'")
  end  

  def priority_name
    priority.name if priority
  end
  
  def priority_name=(n)
    self.priority = Priority.find_by_name(n) unless n.blank?
  end

  auto_html_for(:content) do
    redcloth
    youtube(:width => 460, :height => 285)
    vimeo(:width => 460, :height => 260)
    link(:rel => "nofollow")
  end

end
