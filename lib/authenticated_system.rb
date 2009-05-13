module AuthenticatedSystem
  protected
    # Returns true or false if the user is logged in.
    # Preloads @current_user with the user model if they're logged in.
    def logged_in?
      !!current_user
    end
    
    # Accesses the current user from the session. 
    # Future calls avoid the database because nil is not equal to false.
    def current_user
      @current_user ||= (login_from_session || login_from_facebook || login_from_basic_auth || login_from_cookie) unless @current_user == false
    end

    # Store the given user id in the session.
    def current_user=(new_user)
      session[:user_id] = new_user ? new_user.id : nil
      @current_user = new_user || false
    end
    
    # Check if the user is authorized
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorized?
    #    current_user.login != "bob"
    #  end
    def authorized?
      logged_in?
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def login_required
      authorized? || access_denied
    end
    
    def admin_required
      (logged_in? and current_user.is_admin?) || access_denied
    end
    
    def current_user_required
      access_denied unless logged_in? and (current_user.id == params[:id].to_i or current_user.is_admin?)
    end

    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      flash[:notice] = "Please join first.  If you already have an account, use the log in box on the top right."
      respond_to do |format|
        format.html do
          store_location
          redirect_to new_user_path
        end
        format.js do
          store_previous_location
          render :update do |page|
            page.redirect_to new_user_path
          end
        end        
        format.any do
          request_http_basic_authentication 'Web Password'
        end
      end
    end

    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.request_uri
    end
    
    def store_previous_location
      session[:return_to] = request.env['HTTP_REFERER'] || '/'    
    end
    
    def get_previous_location(default='/')
      session[:return_to] = nil       
      return session[:return_to] || default     
    end

    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.
    def redirect_back_or_default(default='/')
      redirect_to(get_previous_location)
    end
    
    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?, :facebook_uid
    end

    # Called from #current_user.  First attempt to login by the user id stored in the session.
    # if they connected to facebook while they were logged in to the site, it will automatically add the facebook uid to their existing account
    def login_from_session
      if session[:user_id]
        u = User.find_by_id(session[:user_id])
        self.current_user = u 
      end
    end
    
    # Called from #current_user. Then try to login from facebook
    def login_from_facebook
      if facebook_session
        if u = User.find_by_facebook_uid(facebook_session.user.uid)
          return u
        end
        u = User.create_from_facebook(facebook_session,current_partner,request)
        if u
          session[:goal] = 'signup'
          return u
        else
          return false
        end
      end
    end
    
    def login_from_basic_auth
      authenticate_with_http_basic do |email, password|
        self.current_user = User.authenticate(email, password)
      end
    end    

    # Called from #current_user.  Attempt to login by an expiring token in the cookie.
    def login_from_cookie
      user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
      if user && user.remember_token?
        cookies[:auth_token] = { :value => user.remember_token, :expires => user.remember_token_expires_at }
        self.current_user = user
      else
        return false
      end
    end

end
