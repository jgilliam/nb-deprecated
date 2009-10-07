class PointsController < ApplicationController
 
  before_filter :login_required, :only => [:new, :create, :quality, :unquality, :your_priorities, :index, :destroy]
  before_filter :admin_required, :only => [:edit, :update]
 
  def index
    @page_title = t('points.yours.title', :government_name => current_government.name)
    @points = Point.published.by_recently_created.paginate :conditions => ["user_id = ?", current_user.id], :include => :priority, :page => params[:page], :per_page => params[:per_page]
    get_qualities
    respond_to do |format|
      format.html { render :action => "index" }
      format.xml { render :xml => @points.to_xml(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def newest
    @page_title = t('points.newest.title', :government_name => current_government.name)
    @points = Point.published.by_recently_created.paginate :include => :priority, :page => params[:page], :per_page => params[:per_page]
    @rss_url = url_for :only_path => false, :format => "rss"
    get_qualities
    respond_to do |format|
      format.html { render :action => "index" }
      format.rss { render :template => "rss/points" }
      format.xml { render :xml => @points.to_xml(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
 
  def your_priorities
    @page_title = t('points.your_priorities.title', :government_name => current_government.name)
    if current_user.endorsements_count > 0    
      if current_user.up_endorsements_count > 0 and current_user.down_endorsements_count > 0
        @points = Point.published.by_recently_created.paginate :conditions => ["(points.priority_id in (?) and points.endorser_helpful_count > 0) or (points.priority_id in (?) and points.opposer_helpful_count > 0)",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact,current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :include => :priority, :page => params[:page], :per_page => params[:per_page]
      elsif current_user.up_endorsements_count > 0
        @points = Point.published.by_recently_created.paginate :conditions => ["points.priority_id in (?) and points.endorser_helpful_count > 0",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact], :include => :priority, :page => params[:page], :per_page => params[:per_page]
      elsif current_user.down_endorsements_count > 0
        @points = Point.published.by_recently_created.paginate :conditions => ["points.priority_id in (?) and points.opposer_helpful_count > 0",current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :include => :priority, :page => params[:page], :per_page => params[:per_page]
      end
      get_qualities      
    else
      @points = nil
    end
    respond_to do |format|
      format.html { render :action => "index" }
      format.xml { render :xml => @points.to_xml(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end 
 
  def revised
    @page_title = t('points.revised.title', :government_name => current_government.name)
    @revisions = Revision.published.by_recently_created.find(:all, :include => :point, :conditions => "points.revisions_count > 1").paginate :page => params[:page], :per_page => params[:per_page]
    @qualities = nil
    if logged_in? and @revisions.any? # pull all their qualities on the points shown
      @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @revisions.collect {|c| c.point_id},current_user.id])
    end    
    respond_to do |format|
      format.html
      format.xml { render :xml => @revisions.to_xml(:include => [:point, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @revisions.to_json(:include => [:point, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end 
 
  # GET /points/1
  def show
    @point = Point.find(params[:id])
    if @point.is_deleted?
      flash[:error] = t('points.deleted')
      redirect_to @point.priority
      return
    end    
    @page_title = @point.name
    @priority = @point.priority
    if logged_in? 
      @quality = @point.point_qualities.find_by_user_id(current_user.id) 
    else
      @quality = nil
    end
    @points = nil
    if @priority.down_points_count > 1 and @point.is_down?
      @points = @priority.points.published.down.by_recently_created.find(:all, :conditions => "id <> #{@point.id}", :include => :priority, :limit => 3)
    elsif @priority.up_points_count > 1 and @point.is_up?
      @points = @priority.points.published.up.by_recently_created.find(:all, :conditions => "id <> #{@point.id}", :include => :priority, :limit => 3)
    elsif @priority.neutral_points_count > 1 and @point.is_neutral?
      @points = @priority.points.published.neutral.by_recently_created.find(:all, :conditions => "id <> #{@point.id}", :include => :priority, :limit => 3)        
    end
    get_qualities if @points and @points.any?
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @point.to_xml(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @point.to_json(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /priorities/1/points/new
  def new
    load_endorsement
    @point = @priority.points.new
    @page_title = t('points.new.title', :priority_name => @priority.name)
    @point.value = @endorsement.value if @endorsement
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def edit
    @point = Point.find(params[:id])
    @priority = @point.priority
  end

  # POST /priorities/1/points
  def create
    load_endorsement
    @priority = Priority.find(params[:priority_id])    
    @point = @priority.points.new(params[:point])
    @point.user = current_user
    @saved = @point.save
    respond_to do |format|
      if @saved
        if Revision.create_from_point(@point.id,request)
          session[:goal] = 'point'
          flash[:notice] = t('points.new.success')
          if facebook_session
            flash[:user_action_to_publish] = UserPublisher.create_point(facebook_session, @point, @priority)
          end          
          @quality = @point.point_qualities.find_or_create_by_user_id_and_value(current_user.id,true)
          format.html { redirect_to(@point) }
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /points/1
  def update
    @point = Point.find(params[:id])
    @priority = @point.priority
    respond_to do |format|
      if @point.update_attributes(params[:point])
        flash[:notice] = t('points.update.success', :point_name => @point.name)
        format.html { redirect_to(@point) }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  # GET /points/1/activity
  def activity
    @point = Point.find(params[:id])
    @page_title = t('points.activity.title', :point_name => @point.name)
    @priority = @point.priority
    if logged_in? 
      @quality = @point.point_qualities.find_by_user_id(current_user.id) 
    else
      @quality = nil
    end
    @activities = @point.activities.active.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  # GET /points/1/discussions
  def discussions
    @point = Point.find(params[:id])
    @page_title = t('points.discussions.title', :point_name => @point.name)
    @priority = @point.priority
    if logged_in? 
      @quality = @point.point_qualities.find_by_user_id(current_user.id) 
    else
      @quality = nil
    end
    @activities = @point.activities.active.discussions.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "activity" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  # POST /points/1/quality
  def quality
    @point = Point.find(params[:id])
    @quality = @point.point_qualities.find_or_create_by_user_id_and_value(current_user.id,params[:value])
    @point.reload    
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == "point_detail"
            page.replace_html 'point_' + @point.id.to_s + '_helpful_button', render(:partial => "points/button", :locals => {:point => @point, :quality => @quality })
            page.replace_html 'point_' + @point.id.to_s + '_helpful_chart', render(:partial => "documents/helpful_chart", :locals => {:document => @point })            
          elsif params[:region] = "point_inline"
            page.replace_html 'point_' + @point.id.to_s + '_quality', render(:partial => "points/button_small", :locals => {:point => @point, :quality => @quality, :priority => @point.priority}) 
          end
        end        
      }
    end
  end  
  
  # POST /points/1/unquality
  def unquality
    @point = Point.find(params[:id])
    @qualities = @point.point_qualities.find(:all, :conditions => ["user_id = ?",current_user.id])
    for quality in @qualities
      quality.destroy
    end
    @point.reload
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == "point_detail"
            page.replace_html 'point_' + @point.id.to_s + '_helpful_button', render(:partial => "points/button", :locals => {:point => @point, :quality => @quality })
            page.replace_html 'point_' + @point.id.to_s + '_helpful_chart', render(:partial => "documents/helpful_chart", :locals => {:document => @point })            
          elsif params[:region] = "point_inline"
            page.replace_html 'point_' + @point.id.to_s + '_quality', render(:partial => "points/button_small", :locals => {:point => @point, :quality => @quality, :priority => @point.priority}) 
          end          
        end       
      }
    end
  end  
  
  # GET /points/1/unhide
  def unhide
    @point = Point.find(params[:id])
    @priority = @point.priority
    @quality = nil
    if logged_in?
      @quality = @point.point_qualities.find_by_user_id(current_user.id)
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace 'point_' + @point.id.to_s, render(:partial => "points/show", :locals => {:point => @point, :quality => @quality})
        end
      }
    end
  end

  # DELETE /points/1
  def destroy
    @point = Point.find(params[:id])
    if @point.user_id != current_user.id and not current_user.is_admin?
      flash[:error] = t('point.destroy.access_denied')
      redirect_to(@point)
      return
    end
    @point.delete!
    ActivityPointDeleted.create(:user => current_user, :point => @point)
    respond_to do |format|
      format.html { redirect_to(points_url) }
    end
  end
  
  private
    def load_endorsement
      @priority = Priority.find(params[:priority_id])    
      @endorsement = nil
      if logged_in? # pull all their endorsements on the priorities shown
        @endorsement = @priority.endorsements.active.find_by_user_id(current_user.id)
      end    
    end  
    def get_qualities
      @qualities = nil
      if logged_in? and @points.any? # pull all their qualities on the points shown
        @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @points.collect {|c| c.id},current_user.id])
      end    
    end    
    
end
