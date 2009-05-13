class NotificationsController < ApplicationController

  before_filter :login_required
  
  def authorized?
    @notification = Notification.find(params[:id])
    current_user.is_admin? or @notification.recipient_id == current_user.id
  end

  # GET /notifications/1
  # GET /notifications/1.xml
  def show
    respond_to do |format|
      format.html
      format.xml { render :xml => @notification.to_xml(:include => [:sender, :notifiable], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @notification.to_json(:include => [:sender, :notifiable], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # DELETE /notifications/1
  # DELETE /notifications/1.xml
  def destroy
    @notification.delete!
    respond_to do |format|
      format.html { redirect_to(:controller => "inbox", :action => "notifications") }
      format.js {
        render :update do |page|
          page.remove 'notification_' + @notification.id.to_s
        end        
      }
    end
  end
end
