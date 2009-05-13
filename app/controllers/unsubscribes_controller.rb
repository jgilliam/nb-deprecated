class UnsubscribesController < ApplicationController
  
  # GET /unsubscribes/new
  # GET /unsubscribes/new.xml
  def new
    redirect_to signups_settings_url and return if logged_in?
    @page_title = "Manage email notifications"
    @unsubscribe = Unsubscribe.new
    @unsubscribe.is_comments_subscribed = true
    @unsubscribe.is_votes_subscribed = true
    @unsubscribe.is_newsletter_subscribed = true
    @unsubscribe.is_point_changes_subscribed = true
    @unsubscribe.is_followers_subscribed = true
    @unsubscribe.is_finished_subscribed = true    
    @unsubscribe.is_messages_subscribed = true    
    respond_to do |format|
      format.html # new.html.erb
    end
  end


  # POST /unsubscribes
  # POST /unsubscribes.xml
  def create
    @unsubscribe = Unsubscribe.new(params[:unsubscribe])
    @page_title = "Manage email notifications"    
    respond_to do |format|
      if @unsubscribe.save
        flash[:notice] = t('unsubscribe.success', :government_name => current_government.name)
        format.html { redirect_to('/') }
      else
        format.html { render :action => "new" }
      end
    end
  end

end
