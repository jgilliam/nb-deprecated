class InstallController < ApplicationController

  layout false

  protect_from_forgery :only => :blah

  skip_before_filter :check_installation
  skip_before_filter :set_facebook_session
  skip_before_filter :load_actions_to_publish
  skip_before_filter :check_subdomain
  skip_before_filter :check_blast_click
  skip_before_filter :check_priority
  skip_before_filter :check_referral
  skip_before_filter :check_suspension
  skip_before_filter :update_loggedin_at
  skip_before_filter :check_facebook
  
  before_filter :set_current_government
  
  # new single government mode installs will redirect here if there's no government set
  def index
    redirect_to :action => "admin_user" if current_government
    @government = Government.new
  end

  def create
    redirect_to :action => "admin_user" if current_government    
    @government = Government.new(params[:government])
    @government.status = 'active'
    @government.short_name = 'single'
    @government.email = @government.admin_email
    @government.layout = "basic"
    if @government.save
      ColorScheme.create(:input => "FFFFFF")
      # if running mysql, these tables should be MyISAM, not InnoDB.      
      if User.adapter == 'mysql'
        Government.connection.execute("ALTER TABLE rankings ENGINE=MYISAM")
        Government.connection.execute("ALTER TABLE user_rankings ENGINE=MYISAM")    
        Government.connection.execute("ALTER TABLE pictures ENGINE=MYISAM")      
      end
      redirect_to :action => "admin_user"
    else
      render :action => "index"
    end
  end
  
  def admin_user
    redirect_to "/" and return if User.admins.first
    @user = User.new
    @user.email = current_government.admin_email
    @user.login = current_government.admin_name
  end
  
  def create_admin_user
    @user = User.new(params[:user])
    if @user.save
      cookies.delete :auth_token
      self.current_user = @user
      @user.is_admin = true
      @user.save_with_validation(false)
      CapitalGovernmentNew.create(:recipient => @user, :amount => 5)   
      flash[:notice] = t('install.welcome.success_loggedin')
      redirect_to "/"         
    else
      render :action => "admin_user"
    end
  end
  
  private
  def set_current_government
    Government.current = current_government if current_government
  end

end
