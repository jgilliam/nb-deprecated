class PointQuality < ActiveRecord::Base

  extend ActiveSupport::Memoizable

  belongs_to :user
  belongs_to :point
  
  after_create :add_point_counts
  before_destroy :remove_point_counts
  
  def add_point_counts
    if self.is_helpful?
      point.helpful_count += 1
      point.endorser_helpful_count += 1 if is_endorser?
      point.neutral_helpful_count += 1 if is_neutral?      
      point.opposer_helpful_count += 1 if is_opposer?
      point.calculate_score
      point.save_with_validation(false)
      ActivityPointHelpful.create(:point => point, :user => user, :priority => point.priority)      
    end
    if not self.is_helpful?
      point.unhelpful_count += 1
      point.endorser_unhelpful_count += 1 if is_endorser?
      point.neutral_unhelpful_count += 1 if is_neutral?      
      point.opposer_unhelpful_count += 1 if is_opposer?
      point.calculate_score
      point.save_with_validation(false)
      ActivityPointUnhelpful.create(:point => point, :user => user, :priority => point.priority)
    end
    user.increment!(:qualities_count)
  end
  
  def remove_point_counts
    if self.is_helpful?
      point.helpful_count -= 1
      point.endorser_helpful_count -= 1 if is_endorser?
      point.neutral_helpful_count -= 1 if is_neutral?      
      point.opposer_helpful_count -= 1 if is_opposer?
      point.calculate_score
      point.save_with_validation(false)
      ActivityPointHelpfulDelete.create(:point => point, :user => user, :priority => point.priority)        
    end
    if not self.is_helpful?
      point.unhelpful_count -= 1
      point.endorser_unhelpful_count -= 1 if is_endorser?
      point.neutral_unhelpful_count -= 1 if is_neutral?      
      point.opposer_unhelpful_count -= 1 if is_opposer?
      point.calculate_score
      point.save_with_validation(false)
      ActivityPointUnhelpfulDelete.create(:point => point, :user => user, :priority => point.priority)      
    end
    user.decrement!(:qualities_count)    
  end
  
  def is_helpful?
    value
  end
  
  def is_unhelpful?
    not value
  end  
  
  def endorsement
    user.endorsements.active_and_inactive.find_by_priority_id(point.priority_id)    
  end 
  memoize :endorsement
  
  def is_endorser?
    endorsement and endorsement.is_up?
  end
  
  def is_neutral?
    not endorsement
  end
  
  def is_opposer?
    endorsement and endorsement.is_down?
  end
  
end
