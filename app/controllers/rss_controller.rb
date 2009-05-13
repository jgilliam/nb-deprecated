class RssController < ApplicationController
  
  skip_before_filter :check_blast_click
  skip_before_filter :check_subdomain
  skip_before_filter :check_priority
  skip_before_filter :check_referral    
  skip_before_filter :update_loggedin_at
  skip_before_filter :check_facebook
  
  before_filter :login_from_rss_code

  def your_notifications
    @page_title = t('rss.your_notifications', :user_name => @user.login.possessive, :government_name => current_government.name)
    @notifications = @user.received_notifications.active.by_recently_created.find(:all, :include => [:notifiable]).paginate :page => params[:page]
    respond_to do |format|
      format.rss { render :template => "rss/notifications" }
    end
  end
  
  def your_comments
    @page_title = t('rss.your_comments', :user_name => @user.login.possessive, :government_name => current_government.name)
    @notifications = @user.received_notifications.active.comments.by_recently_created.find(:all, :include => [:notifiable]).paginate :page => params[:page]
    respond_to do |format|
      format.rss { render :template => "rss/notifications" }
    end
  end  
  
  def your_priorities_created_activities
    @page_title = t('news.your_priorities_created_activities.title', :government_name => current_government.name)
    @activities = nil
    created_priority_ids = @user.created_priorities.collect{|p|p.id}
    if created_priority_ids.any?
      @activities = Activity.active.by_recently_created.paginate :conditions => ["priority_id in (?)",created_priority_ids], :page => params[:page]
    end
    respond_to do |format|
      format.rss { render :template => "rss/activities" }
    end
  end
  
  private

  def login_from_rss_code
    return false unless request.format == 'rss' and params[:c] and params[:c].length == 40
    @user =  User.find_by_rss_code(params[:c])
  end
  
end
