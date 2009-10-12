class TwitterController < ApplicationController

  def self.consumer
    OAuth::Consumer.new(ENV['TWITTER_KEY'],ENV['TWITTER_SECRET_KEY'],{ :site=>"http://twitter.com" })  
  end

  def create
    store_previous_location    
    @request_token = TwitterController.consumer.get_request_token
    session[:request_token] = @request_token.token
    session[:request_token_secret] = @request_token.secret
    # Send to twitter.com to authorize
    redirect_to @request_token.authorize_url.gsub('authorize', 'authenticate')
    return
  end

  def callback
    # Exchange the request token for an access token.
    stored_request_token = session[:request_token]
    stored_request_token_secret = session[:request_token_secret]
    @request_token = OAuth::RequestToken.new(TwitterController.consumer, stored_request_token, stored_request_token_secret)   
    @access_token = @request_token.get_access_token
    @response = TwitterController.consumer.request(:get, '/account/verify_credentials.json', @access_token, { :scheme => :query_string })
    if @response.class == Net::HTTPOK
      user_info = JSON.parse(@response.body)
      if not user_info['screen_name']
        flash[:error] = t('sessions.create.failed_twitter')
        redirect_to Government.current.homepage_url + "twitter/failed"
        return
      else
        if logged_in? # they are already logged in, need to sync this account to twitter
          u = User.find(current_user.id)
          u.update_with_twitter(user_info, @access_token.token, @access_token.secret, request)
          Delayed::Job.enqueue LoadTwitterFollowers.new(u.id), 1
          redirect_to Government.current.homepage_url + "twitter/connected"
          return          
        else # they aren't logged in, so we'll log them in to twitter
          u = User.find_by_twitter_id(user_info['id'].to_i)
          u = User.find_by_twitter_login(user_info['screen_name']) if not u
          if u # let's add the tokens to the account
            u.update_with_twitter(user_info, @access_token.token, @access_token.secret, request)
          end          
          # if we haven't found their account, let's create it...
          if not u
            u = User.create_from_twitter(user_info, @access_token.token, @access_token.secret, request) 
            Delayed::Job.enqueue LoadTwitterFollowers.new(u.id), 1
          end
          if u # now it's time to update memcached (or their cookie if in single govt mode) that we've got their acct
            self.current_user = u
            self.current_user.remember_me unless current_user.remember_token?
            cookies[:auth_token] = { :value => self.current_user.remember_token, :expires => self.current_user.remember_token_expires_at }
            redirect_to Government.current.homepage_url + "twitter/success"
          else
            redirect_to Government.current.homepage_url + "twitter/failed"
          end 
          return
        end
      end
    else
      RAILS_DEFAULT_LOGGER.error "Failed to get twitter user info via OAuth"
      # The user might have rejected this application. Or there was some other error during the request.
      redirect_to Government.current.homepage_url + "twitter/failed"
      return
    end
  end
  
  def success
    flash[:notice] = t('sessions.create.success', :government_name => Government.current.name, :user_name => current_user.name)
    redirect_back_or_default('/')
  end
  
  def connected
    flash[:notice] = t('settings.twitter_connected')
    redirect_back_or_default('/')
  end
  
  def failed
    flash[:error] = t('sessions.create.failed_twitter')
    redirect_back_or_default('/')
  end

end
