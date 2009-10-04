require 'digest/sha1'
class ImportController < ApplicationController

  before_filter :login_required
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
      path = request.request_uri
      Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], false)    
      logger.info "loading yahoo contacts for " + @user.name    
      @user.load_yahoo_contacts(path)
      @user.calculate_contacts_count
      @user.save_with_validation(false)
      logger.info "done loading yahoo contacts for " + @user.name
      Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], true)      
    end
    redirect_to :action => "status"
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
      Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], false)    
      logger.info "loading windows contacts for " + @user.name    
      @user.load_windows_contacts(request.raw_post)
      @user.calculate_contacts_count
      @user.save_with_validation(false)
      logger.info "done loading windows contacts for " + @user.name
      Rails.cache.write(["#{Government.current.short_name}-contacts_finished",@user.id], true)      
    end
    redirect_to :action => "status"
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
  
end
