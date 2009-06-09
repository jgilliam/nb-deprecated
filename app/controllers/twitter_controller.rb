class TwitterController < ApplicationController

  before_filter :change_government

  def self.consumer
    OAuth::Consumer.new(ENV['TWITTER_KEY'],ENV['TWITTER_SECRET_KEY'],{ :site=>"http://twitter.com" })  
  end

  def create
    store_previous_location    
    @request_token = TwitterController.consumer.get_request_token
    if NB_CONFIG['multiple_government_mode'] and not current_government.is_custom_domain?
      random_key = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
      @ci = Hash.new
      @ci[:current_user] = current_user
      @ci[:current_government] = current_government
      @ci[:request_token] = @request_token.token
      @ci[:request_token_secret] = @request_token.secret
      Rails.cache.write("misc-login-" + random_key, @ci)
      cookies[:misc_login] = { :value => random_key, :domain => '.' + NB_CONFIG['multiple_government_base_url'] }    
    else
      session[:request_token] = @request_token.token
      session[:request_token_secret] = @request_token.secret
    end
    # Send to twitter.com to authorize
    redirect_to @request_token.authorize_url.gsub('authorize', 'authenticate')
    return
  end
  
  ##
  ##  this needs to change to pass the current_user and current_government back through memcache and the misc_login cookie
  ##

  def callback
    # Exchange the request token for an access token.
    if NB_CONFIG['multiple_government_mode'] and not current_government.is_custom_domain?
      stored_request_token = @ci[:request_token]
      stored_request_token_secret = @ci[:request_token_secret]
    else
      stored_request_token = session[:request_token]
      stored_request_token_secret = session[:request_token_secret]
    end
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
          redirect_to Government.current.homepage_url + "twitter/connected"
          return          
        else # they aren't logged in, so we'll log them in to twitter
          u = User.find_by_twitter_id(user_info['id'].to_i)
          u = User.find_by_twitter_login(user_info['screen_name']) if not u
          if u # let's add the tokens to the account
            u.update_with_twitter(user_info, @access_token.token, @access_token.secret, request)
          end          
          # if we haven't found their account, let's create it...
          u = User.create_from_twitter(user_info, @access_token.token, @access_token.secret, request) if not u
          if u # now it's time to update memcached (or their cookie if in single govt mode) that we've got their acct
            if NB_CONFIG['multiple_government_mode'] and not current_government.is_custom_domain?
              @ci[:current_user] = u
              Rails.cache.write("misc-login-" + cookies[:misc_login], @ci)
            else
              self.current_user = u
              self.current_user.remember_me unless current_user.remember_token?
              cookies[:auth_token] = { :value => self.current_user.remember_token, :expires => self.current_user.remember_token_expires_at }
            end
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
    if NB_CONFIG['multiple_government_mode'] and not current_government.is_custom_domain?
      @ci = Rails.cache.read("misc-login-" + cookies[:misc_login])
      if not @ci[:current_user]
        redirect_to :action => "failed"
        return
      end
      self.current_user = User.find(@ci[:current_user].id)
      self.current_user.remember_me unless current_user.remember_token?
      cookies[:auth_token] = { :value => self.current_user.remember_token, :expires => self.current_user.remember_token_expires_at, :domain => '.' + NB_CONFIG['multiple_government_base_url'] }
      Rails.cache.delete("misc-login-" + cookies[:misc_login])
      cookies.delete(:misc_login, :domain => '.' + NB_CONFIG['multiple_government_base_url'] )
    end
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
  
  private
  
    def change_government
      if is_misc? and cookies[:misc_login]
        @ci = Rails.cache.read("misc-login-" + cookies[:misc_login])
        @ci[:current_government].switch_db
        self.current_government = @ci[:current_government]
        self.current_user = @ci[:current_user]
      end
    end

end
