class ActivitiesController < ApplicationController
  
  before_filter :admin_required, :only => [:edit, :update]
  before_filter :login_required, :only => [:destroy, :undelete]
  
  def index
    if request.format != 'html'
      @activities = Activity.active.by_recently_created.paginate :page => params[:page]
    end
    respond_to do |format|
      format.html { redirect_to :controller => "news", :action => "activities" } # redirect to all activity
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => WH2_CONFIG['api_exclude_fields']) }      
    end    
  end

  # GET /activities/1
  # GET /activities/1.xml
  def show
    @activity = Activity.find(params[:id])
    respond_to do |format|
      format.html { redirect_to activity_comments_url(@activity) }
      format.xml { render :xml => @activity.to_xml(:include => :user, :except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activity.to_json(:include => :user, :except => WH2_CONFIG['api_exclude_fields']) }      
    end    
  end
  
  #GET /activities/1/unhide
  def unhide
    @activity = Activity.find(params[:id])    
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace 'activity_and_comments_' + @activity.id.to_s, render(:partial => "activities/show", :locals => {:activity => @activity, :suffix => ""})
        end
      }
    end
  end

  # PUT /activities/1
  # PUT /activities/1.xml
  def update
    @activity = Activity.find(params[:id])

    respond_to do |format|
      if @activity.update_attributes(params[:activity])
        flash[:notice] = 'Activity was successfully updated.'
        format.html { redirect_to(@activity) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /activities/1
  # DELETE /activities/1.xml

  def destroy
    @activity = Activity.find(params[:id])
    access_denied unless current_user.is_admin? or @activity.user_id == current_user.id
    @activity.delete!
    respond_to do |format|
      format.html { redirect_to(activities_url) }
      format.js {
        render :update do |page|
          page.remove 'activity_and_comments_' + @activity.id.to_s
        end        
      }
    end
  end

  # PUT /activities/1/undelete
  def undelete
    @activity = Activity.find(params[:id])
    @activity.undelete!
    respond_to do |format|
      format.html { redirect_to(activities_url) }
    end
  end

end
