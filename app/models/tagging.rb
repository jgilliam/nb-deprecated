class Tagging < ActiveRecord::Base #:nodoc:
  
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  belongs_to :tagger, :polymorphic => true
  
  validates_presence_of :context
  
  belongs_to :priority, :class_name => "Priority", :foreign_key => "taggable_id"
  belongs_to :webpage, :class_name => "Webpage", :foreign_key => "taggable_id"
  belongs_to :feed, :class_name => "Feed", :foreign_key => "taggable_id"
      
  after_create :increment_tag
  before_destroy :decrement_tag
  
  def increment_tag
    if taggable.class == Webpage
      tag.increment!(:webpages_count)
    elsif taggable.class == Priority
      tag.increment!(:priorities_count)
    elsif taggable.class == Feed
      tag.increment!(:feeds_count)      
    end
  end
  
  def decrement_tag
    if taggable.class == Webpage
      tag.decrement!(:webpages_count)
    elsif taggable.class == Priority
      tag.decrement!(:priorities_count)    
    elsif taggable.class == Feed
      tag.decrement!(:feeds_count)        
    end    
  end
  
end