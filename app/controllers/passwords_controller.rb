class PasswordsController < ApplicationController

  before_filter :login_from_cookie
  before_filter :login_required, :except => [:create, :new]
  before_filter :current_user_required, :only => [:edit, :update]

  # Don't write passwords as plain text to the log files
  filter_parameter_logging :old_password, :password, :password_confirmation

  # GETs should be safe
  verify :method => :post, :only => [:create], :redirect_to => { :controller => :users }
  verify :method => :put, :only => [:update], :redirect_to => { :controller => :users }

  # POST /passwords
  # Forgot password
  
  # If a user is logged in and they want to change their password
  # link to edit_user_path(current_user). 
  # If a user is not logged in and has forgotten their password, 
  # link to the forgot password view by using new_password_path().  
  
  def new
    @page_title = t('passwords.new.title',:government_name => current_government.name)
  end
  
  def create
    @page_title = t('passwords.new.title',:government_name => current_government.name)
    users = User.find(:all, :conditions => ["email = ? and status in ('active','pending','passive')",params[:email]])
    if users.any?
      user = users[0]
      if user.has_facebook?
        flash[:error] = t('passwords.new.facebook',:government_name => current_government.name)
        redirect_to :action => "new"
        return
      else
        user.reset_password
        flash[:notice] = t('passwords.new.sent', :email => user.email)
        redirect_to login_path
        return
      end      
    else
      user = nil
      flash[:error] =  t('users.missing')
      redirect_to :action => "new"
      return
    end
  end

  # GET /users/1/password/edit
  # Changing password
  def edit
    @page_title = t('passwords.change.title',:government_name => current_government.name)
    @user = current_user
    if @user.has_facebook?
      flash[:error] = t('passwords.change.facebook',:government_name => current_government.name)
      return
    end
  end

  # PUT /users/1/password
  # Changing password
  def update
    @user = current_user
    old_password = params[:old_password]
    @user.attributes = params[:user]

    respond_to do |format|
      if @user.authenticated?(old_password) && @user.save
        flash[:notice] = t('passwords.change.success')
        format.html { redirect_to edit_password_url(@user) }
      else
        flash[:error] = t('passwords.change.nomatch')
        format.html { render :action => 'edit' }
      end
    end
  end

end
