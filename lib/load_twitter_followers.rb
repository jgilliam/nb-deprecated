class LoadTwitterFollowers
  
  attr_accessor :id
  
  def initialize(id)
    @id = id
  end

  def perform
    Government.current = Government.all.last
    user = User.find(@id)
    if not user.attribute_present?("twitter_crawled_at")
      user.twitter_followers_follow
    end
    user.follow_twitter_friends
    user.update_attribute(:twitter_crawled_at, Time.now)
    c = user.twitter_followers_count
    user.update_attribute(:twitter_count, c) if c != user.twitter_count
  end
  
end