class Constituent < ActiveRecord::Base

  belongs_to :legislator
  belongs_to :user
  
  after_create :add_counts
  before_destroy :remove_counts

  def add_counts
    user.increment!(:constituents_count)
    legislator.increment!(:constituents_count)    
  end

  def remove_counts
    user.decrement!(:constituents_count)
    legislator.decrement!(:constituents_count)    
  end

end
