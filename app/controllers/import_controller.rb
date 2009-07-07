require 'digest/sha1'
class ImportController < ApplicationController

  before_filter :login_required, :unless => :is_misc?
  before_filter :change_government, :except => [:status, :google]
  
  protect_from_forgery :except => :windows
  
  def google
    if not current_user.attribute_present?("google_token") and not params[:token]
      redirect_to Contacts::Google.authentication_url(url_for(:only_path => false, :controller => "import", :action => "google"), :session => true)
      return
    elsif params[:token]
      token = Contacts::Google.session_token(params[:token])      
      current_user.update_attribute(:google_token,token)
    end 
    @user = User.find(current_user.id)
    Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], false)
    Rails.cache.write(["#{Government.current.short_name}-contacts_number",@user.id], 0)
    spawn do
      current_government.switch_db      
      logger.info "loading google contacts for " + @user.name    
      @user.load_google_contacts
      @user.calculate_contacts_count
      @user.google_crawled_at = Time.now    
      @user.save_with_validation(false)
      logger.info "done loading google contacts for " + @user.name
      Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], true)
    end    
    redirect_to :action => "status"
  end
  
  def yahoo
    if not request.request_uri.include?('token')
      redirect_to Contacts::Yahoo.new.get_authentication_url
      return
    end
    @user = User.find(@ci[:current_user].id)
    Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], false)
    Rails.cache.write(["#{Government.current.short_name}-contacts_number",@user.id], 0)
    spawn do
      Government.current.switch_db
      path = request.request_uri
      Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], false)    
      logger.info "loading yahoo contacts for " + @user.name    
      @user.load_yahoo_contacts(path)
      @user.calculate_contacts_count
      @user.save_with_validation(false)
      logger.info "done loading yahoo contacts for " + @user.name
      Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], true)      
    end
    if is_misc?
      redirect_to 'http://' + Government.current.base_url + '/import/status'
    else
      redirect_to :action => "status"
    end
  end  

  def windows
    if not request.post?
      redirect_to Contacts::WindowsLive.new.get_authentication_url 
      return
    end
    @user = User.find(@ci[:current_user].id)
    Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], false)
    Rails.cache.write(["#{Government.current.short_name}-contacts_number",@user.id], 0)
    spawn do
      Government.current.switch_db
      Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], false)    
      logger.info "loading windows contacts for " + @user.name    
      @user.load_windows_contacts(request.raw_post)
      @user.calculate_contacts_count
      @user.save_with_validation(false)
      logger.info "done loading windows contacts for " + @user.name
      Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], true)      
    end
    if is_misc?
      redirect_to 'http://' + Government.current.base_url + '/import/status'
    else
      redirect_to :action => "status"
    end
  end

  def status
    @page_title = t('import.started')
    @number_completed = Rails.cache.read([current_government.short_name + "-contacts_number",current_user.id])
    @finished = Rails.cache.read([current_government.short_name + "-contacts_finished",current_user.id])
    respond_to do |format|
      if @finished
        flash[:notice] = t('import.finished')
        if current_user.contacts_members_count > 0
          format.html { redirect_to members_user_contacts_path(current_user) }
          format.js { redirect_from_facebox(members_user_contacts_path(current_user)) }
        else
          format.html { redirect_to not_invited_user_contacts_path(current_user) }
          format.js { redirect_from_facebox(not_invited_user_contacts_path(current_user)) }          
        end
      else
        format.html
        format.js {
          render :update do |page|        
            page[:number_completed].replace_html @number_completed
          end
        }
      end
    end
  end
  
  private
  
    def change_government
      if is_misc? and cookies[:misc_login]
        @ci = Rails.cache.read("misc-login-" + cookies[:misc_login])
        @ci[:current_government].switch_db
      elsif not is_misc? and NB_CONFIG['multiple_government_mode']
        random_key = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
        @ci = Hash.new
        @ci[:current_user] = current_user
        @ci[:current_government] = current_government
        Rails.cache.write("misc-login-" + random_key, @ci)
        cookies[:misc_login] = { :value => random_key, :domain => '.' + NB_CONFIG['multiple_government_base_url'] }
      end
    end

end
