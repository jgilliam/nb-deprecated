class Following < ActiveRecord::Base
  
  named_scope :up, :conditions => "value > 0"
  named_scope :down, :conditions => "value < 0"
  
  belongs_to :user
  belongs_to :other_user, :class_name => "User"
  
  has_many :notifications, :as => :notifiable, :dependent => :destroy
  
  after_create :add_counts
  before_destroy :remove_counts
  
  def is_ignore?
    value < 0
  end
  
  def is_follow?
    value > 0
  end    
  
  def is_up?
    is_follow?
  end
  
  def is_down?
    is_ignore?
  end
  
  def add_counts
    if is_ignore?
      user.increment!(:ignorings_count)
      other_user.increment!(:ignorers_count)
      #ActivityIgnoringNew.create(:user => user, :other_user => other_user)
      ActivityCapitalIgnorers.create(:user => other_user, :other_user => user, :capital => CapitalIgnorers.create(:recipient => other_user, :amount => -1))
    else
      user.increment!(:followings_count)
      other_user.increment!(:followers_count)
      ActivityFollowingNew.create(:user => user, :other_user => other_user)
      ActivityCapitalFollowers.create(:user => other_user, :other_user => user, :capital => CapitalFollowers.create(:recipient => other_user, :amount => 1))
      notifications << NotificationFollower.new(:sender => self.user, :recipient => self.other_user)    
    end
  end
  
  def remove_counts
    if is_ignore?
      user.decrement!(:ignorings_count)
      other_user.decrement!(:ignorers_count)      
      #ActivityIgnoringDelete.create(:user => user, :other_user => other_user)
      ActivityCapitalIgnorers.create(:user => other_user, :other_user => user, :capital => CapitalIgnorers.create(:recipient => other_user, :amount => 1))
    else
      user.decrement!(:followings_count)
      other_user.decrement!(:followers_count)
      ActivityFollowingDelete.create(:user => user, :other_user => other_user)    
      ActivityCapitalFollowers.create(:user => other_user, :other_user => user, :capital => CapitalFollowers.create(:recipient => other_user, :amount => -1))
    end
  end

end
