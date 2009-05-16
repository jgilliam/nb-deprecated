class InstallController < ApplicationController

  layout false

  skip_before_filter :set_facebook_session
  skip_before_filter :check_subdomain
  skip_before_filter :check_blast_click
  skip_before_filter :check_priority
  skip_before_filter :check_referral
  skip_before_filter :check_suspension
  skip_before_filter :update_loggedin_at
  skip_before_filter :check_facebook
  
  def load_first_user
    redirect_to "/" and return if User.first # if there's already a user account, don't do anything
    
    @user = User.create(:login => current_government.admin_name, :first_name => "Administrator", :last_name => "Account", :email => current_government.admin_email, :password => "blahblah", :password_confirmation => "blahblah", :is_admin => true)
    @user.reset_password
    CapitalGovernmentNew.create(:recipient => @user, :amount => 5)
    flash[:notice] = t('install.welcome.success', :admin_email => current_government.admin_email)
    redirect_to "/"
  end  

end
