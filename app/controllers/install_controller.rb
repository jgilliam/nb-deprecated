class InstallController < ApplicationController

  layout false

  skip_before_filter :hijack_db
  skip_before_filter :check_subdomain
  skip_before_filter :check_blast_click
  skip_before_filter :check_priority
  skip_before_filter :check_referral
  skip_before_filter :check_suspension
  skip_before_filter :update_loggedin_at
  skip_before_filter :check_facebook
  
  def load_db
    current_government.switch_db_back
    # this will generate an error if the database already exists
    Government.connection.execute("CREATE DATABASE #{current_government.db_name} character SET utf8 COLLATE utf8_general_ci")
    current_government.switch_db
    file = "#{RAILS_ROOT}/db/schema.rb"
    load(file)
    User.connection.execute("ALTER TABLE rankings ENGINE=MYISAM")
    User.connection.execute("ALTER TABLE user_rankings ENGINE=MYISAM")    
    User.connection.execute("ALTER TABLE pictures ENGINE=MYISAM")
    @user = User.create(:login => current_government.admin_name, :first_name => "Administrator", :last_name => "Account", :email => current_government.admin_email, :password => "blahblah", :password_confirmation => "blahblah", :is_admin => true)
    @user.reset_password
    CapitalGovernmentNew.create(:recipient => @user, :amount => 5)
    flash[:notice] = t('install.welcome.success', :admin_email => current_government.admin_email)
    redirect_to "/"
  end  

end
