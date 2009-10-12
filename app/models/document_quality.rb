class DocumentQuality < ActiveRecord::Base

  extend ActiveSupport::Memoizable

  belongs_to :user
  belongs_to :document
  
  after_create :add_counts
  before_destroy :remove_counts
  
  def add_counts
    if self.is_helpful?
      document.helpful_count += 1
      document.endorser_helpful_count += 1 if is_endorser?
      document.neutral_helpful_count += 1 if is_neutral?      
      document.opposer_helpful_count += 1 if is_opposer?
      document.calculate_score
      document.save_with_validation(false)
      ActivityDocumentHelpful.create(:document => document, :user => user, :priority => document.priority)      
    end
    if not self.is_helpful?
      document.unhelpful_count += 1
      document.endorser_unhelpful_count += 1 if is_endorser?
      document.neutral_unhelpful_count += 1 if is_neutral?      
      document.opposer_unhelpful_count += 1 if is_opposer?
      document.calculate_score
      document.save_with_validation(false)
      ActivityDocumentUnhelpful.create(:document => document, :user => user, :priority => document.priority)
    end
    user.increment!(:qualities_count)
  end
  
  def remove_counts
    if self.is_helpful?
      document.helpful_count -= 1
      document.endorser_helpful_count -= 1 if is_endorser?
      document.neutral_helpful_count -= 1 if is_neutral?      
      document.opposer_helpful_count -= 1 if is_opposer?
      document.send_later(:calculate_score, true)
      document.save_with_validation(false)
      ActivityDocumentHelpfulDelete.create(:document => document, :user => user, :priority => document.priority)        
    end
    if not self.is_helpful?
      document.unhelpful_count -= 1
      document.endorser_unhelpful_count -= 1 if is_endorser?
      document.neutral_unhelpful_count -= 1 if is_neutral?      
      document.opposer_unhelpful_count -= 1 if is_opposer?
      document.send_later(:calculate_score, true)
      document.save_with_validation(false)
      ActivityDocumentUnhelpfulDelete.create(:document => document, :user => user, :priority => document.priority)      
    end
    user.decrement!(:qualities_count)    
  end
  
  def is_helpful?
    value > 0
  end
  
  def is_unhelpful?
    value < 0
  end  
  
  def endorsement
    user.endorsements.active_and_inactive.find_by_priority_id(document.priority_id)    
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
