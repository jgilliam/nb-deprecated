class FollowingDiscussion < ActiveRecord::Base

  belongs_to :user
  belongs_to :activity

  has_many :notifications, :as => :notifiable, :dependent => :destroy
  
  after_create :add_counts
  before_destroy :remove_counts
  
  def add_counts
    activity.increment!(:followers_count)
    ActivityDiscussionFollowingNew.create(:user => user, :activity => activity)
  end
  
  def remove_counts
    activity.decrement!(:followers_count)
    ActivityDiscussionFollowingDelete.create(:user => user, :activity => activity)    
  end

end
