class InboxController < ApplicationController

  before_filter :login_required
  
  def index
    @page_title = t('inbox.index')
    @messages = Message.sent.by_recently_sent.find(:all, :conditions => ["recipient_id = ?",current_user.id], :include => [:sender, :recipient]).paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @messages.to_xml(:include => [:sender, :recipient], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @messages.to_json(:include => [:sender, :recipient], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def sent
    @page_title =  t('inbox.sent')
    @messages = Message.sent.by_recently_sent.find(:all, :conditions => ["sender_id = ?",current_user.id]).paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @messages.to_xml(:include => [:sender, :recipient], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @messages.to_json(:include => [:sender, :recipient], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def notifications
    @page_title =  t('inbox.notifications')
    @notifications = current_user.received_notifications.active.by_recently_created.find(:all, :include => [:notifiable]).paginate :page => params[:page], :per_page => params[:per_page]
    @rss_url = url_for(:only_path => false, :controller => "rss", :action => "your_notifications", :format => "rss", :c => current_user.rss_code)
    respond_to do |format|
      format.html
      format.xml { render :xml => @notifications.to_xml(:include => [:notifiable], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @notifications.to_json(:include => [:notifiable], :except => NB_CONFIG['api_exclude_fields']) }
    end
    if request.format == 'html'
      for n in @notifications
        n.read! if n.class != NotificationMessage and n.unread?
      end    
    end
  end  
  
end
