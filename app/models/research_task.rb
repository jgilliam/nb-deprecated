class ResearchTask < ActiveRecord::Base

  named_scope :unclaimed_first, :order => "research_tasks.document_id, research_tasks.finished_at, research_tasks.created_at desc"

  belongs_to :requester, :class_name => "User"
  belongs_to :legislator
  belongs_to :tag
  belongs_to :document
  
  validates_presence_of :name
  validates_length_of :name, :in => 3..60
  validates_presence_of :requester_name, :unless => :has_requester?
  validates_length_of :requester_name, :in => 3..100, :unless => :has_requester?
  validates_length_of :requester_organization, :maximum => 100, :unless => :has_requester?
  validates_presence_of :requester_email, :unless => :has_requester?
  validates_format_of :requester_email, :with => /^[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+$/x, :unless => :has_requester?

  def has_requester?
    requester
  end
  
  def has_document?
    attribute_present?("document_id")
  end
  
  def is_finished?
    attribute_present?("finished_at")
  end
  
  def is_started?
    has_document?
  end
  
  def requester_name_pretty
    if has_requester?
      requester.name
    else
      requester_name
    end
  end
  
end
