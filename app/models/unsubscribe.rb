class Unsubscribe < ActiveRecord::Base
  
  belongs_to :user
  
  validates_presence_of :email

  def validate
    user = User.find_by_email(email)
    if not user
      errors.add("email","is not in our database.")
    end
    errors.on("email")
  end

  before_save :find_user
  after_create :update_user  
  
  def find_user
    user = User.find_by_email(email)
  end
  
  def update_user
    user = User.find_by_email(email)
    user.is_comments_subscribed = self.is_comments_subscribed
    user.is_finished_subscribed = self.is_finished_subscribed    
    user.is_votes_subscribed = self.is_votes_subscribed
    user.is_newsletter_subscribed = self.is_newsletter_subscribed
    user.is_followers_subscribed = self.is_followers_subscribed    
    user.is_point_changes_subscribed = self.is_point_changes_subscribed
    user.is_messages_subscribed = self.is_messages_subscribed
    user.is_votes_subscribed = self.is_votes_subscribed
    user.is_admin_subscribed = self.is_admin_subscribed
    user.save_with_validation(false)
  end
  
end
