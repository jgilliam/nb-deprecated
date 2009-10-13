module TwitterAuth
  
  def self.config(environment=RAILS_ENV)
    {"strategy" => "oauth", "oauth_consumer_key" => ENV["TWITTER_KEY"], "oauth_consumer_secret" => ENV["TWITTER_SECRET_KEY"], "authorize_path" => "/twitter/create", "oauth_callback" => "/twitter/callback"}
  end
  
  module Dispatcher
    class Oauth < OAuth::AccessToken

      def initialize(user)
        raise TwitterAuth::Error, 'Dispatcher must be initialized with a User.' unless user.is_a?(TwitterAuth::OauthUser) 
        self.user = user
        super(TwitterAuth.consumer, user.twitter_token, user.twitter_secret)
      end

    end
  end
  
end