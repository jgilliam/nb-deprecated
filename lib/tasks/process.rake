namespace :process do  
  
  desc "process merge proposals"
  task :merge_proposals => :environment do
    Government.current = Government.all.last    
    changes = Change.find(:all, :conditions => "changes.status = 'sent'", :include => :priority)
    for change in changes
      if change.priority.endorsements_count == 0 # everyone has moved out of the priority, it's alright to end it
        change.approve!
      elsif change.is_expired? and change.is_passing?
        change.approve!
      elsif change.is_expired? and change.yes_votes == 0 and change.no_votes == 0 # no one voted, go ahead and approve it
        change.approve!
      elsif change.is_expired? and change.yes_votes == change.no_votes # a tie! leave it the same
        change.decline!
      elsif change.is_expired? and change.is_failing? # more no votes, decline it
        change.decline!
      end
    end
  end
  
  desc "process notifications and send invitations"
  task :notifications => :environment do
    Government.current = Government.all.last
    for n in Notification.unread.unprocessed.all  # this won't send anything if they've already seen the notification, ie, if they are actively on the site using it.
      n.send!
    end
    for contact in UserContact.tosend.all
      contact.send!
    end      
  end  
  
  desc "new twitterers"
  task :new_twitterers => :environment do
    require 'grackle'
    Government.current = Government.all.last
    if Government.current.has_twitter_enabled?
      users = User.authorized_twitterers.uncrawled_twitterers.active
      for user in users
        if not user.attribute_present?("twitter_crawled_at")
          user.twitter_followers_follow
        end
        user.follow_twitter_friends
        user.update_attribute(:twitter_crawled_at, Time.now)
        c = user.twitter_followers_count
        user.update_attribute(:twitter_count, c) if c != user.twitter_count
      end
    end
  end
  
end