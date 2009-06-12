class Tagging < ActiveRecord::Base
  
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
    return unless tag
    if taggable.class == Webpage
      tag.increment!(:webpages_count)
    elsif taggable.class == Priority
      tag.increment!(:priorities_count)
      tag.update_counts # recalculate the discussions/points/documents
      tag.save_with_validation(false)
    elsif taggable.class == Feed
      tag.increment!(:feeds_count)      
    end
  end
  
  def decrement_tag
    return unless tag
    if taggable.class == Webpage
      tag.decrement!(:webpages_count)
    elsif taggable.class == Priority
      tag.decrement!(:priorities_count)
      tag.update_counts # recalculate the discussions/points/documents
      tag.save_with_validation(false)
    elsif taggable.class == Feed
      tag.decrement!(:feeds_count)        
    end    
  end
  
end