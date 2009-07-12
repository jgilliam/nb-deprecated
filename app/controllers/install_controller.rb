class InstallController < ApplicationController

  layout false

  protect_from_forgery :only => :blah

  skip_before_filter :hijack_db
  skip_before_filter :set_facebook_session
  skip_before_filter :load_actions_to_publish
  skip_before_filter :check_subdomain
  skip_before_filter :check_blast_click
  skip_before_filter :check_priority
  skip_before_filter :check_referral
  skip_before_filter :check_suspension
  skip_before_filter :update_loggedin_at
  skip_before_filter :check_facebook
  
  # new single government mode installs will redirect here if there's no government set
  def index
    redirect_to :action => "load_first_user" if current_government
    @government = Government.new
  end

  def create
    redirect_to :action => "load_first_user" if current_government    
    @government = Government.new(params[:government])
    @government.status = 'active'
    @government.short_name = 'single'
    @government.email = @government.admin_email
    @government.layout = "basic"
    if @government.save
      ColorScheme.create(:input => "FFFFFF")
      # if running mysql, these tables should be MyISAM, not InnoDB.      
      if DB_CONFIG[RAILS_ENV]['adapter'] == 'mysql'
        Government.connection.execute("ALTER TABLE rankings ENGINE=MYISAM")
        Government.connection.execute("ALTER TABLE user_rankings ENGINE=MYISAM")    
        Government.connection.execute("ALTER TABLE pictures ENGINE=MYISAM")      
      end
      redirect_to :action => "load_first_user"
    else
      render :action => "index"
    end
  end
  
  def load_first_user
    redirect_to "/" and return if User.first # if there's already a user account, don't do anything
    Government.current = current_government
    @user = User.create(:login => current_government.admin_name, :first_name => "Administrator", :last_name => "Account", :email => current_government.admin_email, :password => "blahblah", :password_confirmation => "blahblah")
    @user.is_admin = true
    @user.save_with_validation(false)
    @user.reset_password
    CapitalGovernmentNew.create(:recipient => @user, :amount => 5)
    flash[:notice] = t('install.welcome.success', :admin_email => current_government.admin_email)
    redirect_to "/"
  end  

end
