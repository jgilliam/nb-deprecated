class Relationship < ActiveRecord::Base

  named_scope :who_endorsed, :conditions => "relationships.type in ('RelationshipEndorserEndorsed','RelationshipOpposerEndorsed','RelationshipUndecidedEndorsed')"
  named_scope :endorsers_endorsed, :conditions => "relationships.type = 'RelationshipEndorserEndorsed'"
  named_scope :opposers_endorsed, :conditions => "relationships.type = 'RelationshipOpposerEndorsed'"
  named_scope :undecideds_endorsed, :conditions => "relationships.type = 'RelationshipUndecidedEndorsed'"    
  named_scope :by_highest_percentage, :order => "relationships.percentage desc"

  belongs_to :priority
  belongs_to :other_priority, :class_name => "Priority"
  
  after_create :add_counts
  before_destroy :remove_counts
  
  def add_counts
    priority.increment!(:relationships_count)
  end
  
  def remove_counts
    priority.decrement!(:relationships_count)
  end
  
end

class RelationshipEndorserEndorsed < Relationship
  
end

class RelationshipOpposerEndorsed < Relationship
  
end

class RelationshipUndecidedEndorsed < Relationship
  
end
