class PrioritiesController < ApplicationController

  before_filter :login_required, :only => [:yours, :yours_finished, :yours_ads, :yours_top, :yours_lowest, :network, :consider, :flag_inappropriate, :comment, :edit, :update, :tag, :tag_save, :opposed, :endorsed, :yours_created, :destroy]
  before_filter :admin_required, :only => [:bury, :successful, :compromised, :intheworks, :failed]
  before_filter :load_endorsement, :only => [:show, :activities, :endorsers, :opposers, :opposer_points, :endorser_points, :neutral_points, :everyone_points, :discussions, :everyone_points, :documents, :opposer_documents, :endorser_documents, :neutral_documents, :everyone_documents]

  # GET /priorities
  def index
    if params[:q] and request.xhr?
      @priorities = Priority.published.find(:all, :select => "priorities.name", :conditions => ["name LIKE ?", "%#{params[:q]}%"], :order => "endorsements_count desc")
    elsif current_government.homepage != 'index'
      redirect_to :action => current_government.homepage
      return
    else
      @issues = Tag.most_priorities.find(:all, :conditions => "tags.id <> 384 and priorities_count > 4", :include => :top_priority).paginate(:page => params[:page])
      if logged_in? 
        priority_ids = @issues.collect {|c| c.top_priority_id} + @issues.collect {|c| c.rising_priority_id} + @issues.collect {|c| c.controversial_priority_id}
        @endorsements = Endorsement.find(:all, :conditions => ["priority_id in (?) and user_id = ? and status='active'",priority_ids,current_user.id])      
      end
    end
    respond_to do |format|
      format.html
      format.js { 
        if not @priorities
          render :nothing => true
        else
          render :text => @priorities.collect{|p|p.name}.join("\n") 
        end
      }
    end
  end
  
  # GET /priorities/yours
  def yours
    @page_title = t('priorities.yours.title', :government_name => current_government.name)
    @endorsements = current_user.endorsements.active.by_position.paginate :include => :priority, :page => params[:page]
    respond_to do |format|
      format.html 
      format.xml { render :xml => @endorsements.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  # GET /priorities/yours_top
  def yours_top
    @page_title = t('priorities.yours_top.title', :government_name => current_government.name)
    @endorsements = current_user.endorsements.active.by_priority_position.paginate :include => :priority, :page => params[:page]
    respond_to do |format|
      format.html { render :action => "yours" }
      format.xml { render :xml => @endorsements.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  # GET /priorities/yours_lowest
  def yours_lowest
    @page_title = t('priorities.yours_lowest.title', :government_name => current_government.name)
    @endorsements = current_user.endorsements.active.by_priority_lowest_position.paginate :include => :priority, :page => params[:page]
    respond_to do |format|
      format.html { render :action => "yours" }
      format.xml { render :xml => @endorsements.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  # GET /priorities/yours_created  
  def yours_created
    @page_title = t('priorities.yours_created.title', :government_name => current_government.name)
    @priorities = current_user.created_priorities.published.top_rank.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  # GET /priorities/network
  def network
    @page_title = t('priorities.network.title', :government_name => current_government.name)
    if current_user.followings_count > 0
      @network_endorsements = Endorsement.active.find(:all, 
        :select => "endorsements.priority_id, sum((101-endorsements.position)*endorsements.value) as score, count(*) as endorsements_number, priorities.*", 
        :joins => "endorsements INNER JOIN priorities ON priorities.id = endorsements.priority_id", 
        :conditions => ["endorsements.user_id in (?) and endorsements.position < 101",current_following_ids], 
        :group => "endorsements.priority_id",       
        :order => "score desc").paginate :page => params[:page]
        @endorsements = current_user.endorsements.active.find(:all, :conditions => ["priority_id in (?)", @network_endorsements.collect {|c| c.priority_id}])
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @endorsements.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  # GET /priorities/yours_finished
  def yours_finished
    @page_title = t('priorities.yours_finished.title', :government_name => current_government.name)
    @endorsements = current_user.endorsements.finished.find(:all, :order => "priorities.status_changed_at desc", :include => :priority).paginate :page => params[:page]
    respond_to do |format|
      format.html { render :action => "yours" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
    if request.format == 'html' and current_user.unread_notifications_count > 0
      for n in current_user.received_notifications.all
        n.read! if n.class == NotificationPriorityFinished and n.unread?
      end    
    end
  end  

  # GET /priorities/ads
  def ads
    @page_title = t('priorities.ads.title', :government_name => current_government.name)
    @ads = Ad.active_first.paginate :include => [:user, :priority], :page => params[:page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @ads.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ads.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /priorities/yours_ads
  def yours_ads
    @page_title = t('priorities.yours_ads.title', :government_name => current_government.name)
    @ads = current_user.ads.active_first.paginate :include => [:user, :priority], :page => params[:page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @ads.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ads.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  

  # GET /priorities/consider
  def consider
    @page_title = t('priorities.consider.title', :government_name => current_government.name)
    @priorities = current_user.recommend(25)
    if @priorities.empty?
      flash[:error] = t('priorities.consider.need_endorsements')
      redirect_to :action => "random"
      return
    end
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  # GET /priorities/obama
  def obama
    @page_title = t('priorities.official.title', :government_name => current_government.name, :official_user_name => current_government.official_user.name.possessive)
    @rss_url = obama_priorities_url(:format => 'rss')   
    @priorities = Priority.published.obama_endorsed.top_rank.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  # GET /priorities/obama_opposed  
  def obama_opposed
    @page_title = t('priorities.official_opposed.title', :government_name => current_government.name, :official_user_name => current_government.official_user.name)
    @rss_url = obama_opposed_priorities_url(:format => 'rss')       
    @priorities = Priority.published.obama_opposed.top_rank.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  # GET /priorities/not_obama  
  def not_obama
    @page_title = t('priorities.not_official.title', :government_name => current_government.name, :official_user_name => current_government.official_user.name.possessive)
    @rss_url = not_obama_priorities_url(:format => 'rss')       
    @priorities = Priority.published.not_obama.top_rank.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end 
  end  

  # GET /priorities/top
  def top
    @page_title = t('priorities.top.title', :target => current_government.target)
    @rss_url = top_priorities_url(:format => 'rss')   
    @priorities = Priority.published.top_rank.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /priorities/rising
  def rising
    @page_title = t('priorities.rising.title', :target => current_government.target)
    @rss_url = rising_priorities_url(:format => 'rss')           
    @priorities = Priority.published.rising.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  # GET /priorities/falling
  def falling
    @page_title = t('priorities.falling.title', :target => current_government.target)
    @rss_url = falling_priorities_url(:format => 'rss')
    @priorities = Priority.published.falling.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  # GET /priorities/controversial  
  def controversial
    @page_title = t('priorities.controversial.title', :target => current_government.target)
    @rss_url = controversial_priorities_url(:format => 'rss')       
    @priorities = Priority.published.controversial.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  # GET /priorities/finished
  def finished
    @page_title = t('priorities.finished.title', :target => current_government.target)
    @priorities = Priority.finished.by_most_recent_status_change.paginate :page => params[:page]
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  # GET /priorities/random
  def random
    @page_title = t('priorities.random.title', :target => current_government.target)
    @priorities = Priority.published.random.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /priorities/newest
  def newest
    @page_title = t('priorities.newest.title', :target => current_government.target)
    @rss_url = newest_priorities_url(:format => 'rss')     
    @priorities = Priority.published.newest.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  # GET /priorities/untagged
  def untagged
    @page_title = t('priorities.untagged.title', :target => current_government.target)
    @rss_url = untagged_priorities_url(:format => 'rss')            
    @priorities = Priority.published.untagged.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end  
  end  
  
  # GET /priorities/1
  def show
    if @priority.status == 'deleted'
      flash[:notice] = t('priorities.deleted')
    end
    @page_title = @priority.name
    point_ids = []
    if @priority.up_points_count > 0
      @endorser_points = @priority.points.published.by_endorser_helpfulness.find(:all, :limit => 3)
      point_ids += @endorser_points.collect {|c| c.id}
    end
    if @priority.down_points_count > 0
      if point_ids.any? 
        @opposer_points = @priority.points.published.by_opposer_helpfulness.find(:all, :conditions => ["id not in (?)",point_ids], :limit => 3)
      else
        @opposer_points = @priority.points.published.by_opposer_helpfulness.find(:all, :limit => 3)
      end
      point_ids += @opposer_points.collect {|c| c.id}
    end
    if @priority.neutral_points_count > 0
      if point_ids.any?
        @neutral_points = @priority.points.published.by_neutral_helpfulness.find(:all, :conditions => ["id not in (?)",point_ids], :limit => 3)
      else
        @neutral_points = @priority.points.published.by_neutral_helpfulness.find(:all, :limit => 3)
      end
      point_ids += @neutral_points.collect {|c| c.id}        
    end
    @point_ids = point_ids.uniq.compact
    @qualities = nil
    if logged_in? # pull all their qualities on the priorities shown
      @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", point_ids,current_user.id])
    end
    document_ids = []
    if @priority.up_documents_count > 0
      @endorser_documents = @priority.documents.published.by_endorser_helpfulness.find(:all, :limit => 3)
      document_ids += @endorser_documents.collect {|c| c.id}
    end
    if @priority.down_documents_count > 0
      if document_ids.any? 
        @opposer_documents = @priority.documents.published.by_opposer_helpfulness.find(:all, :conditions => ["id not in (?)",document_ids], :limit => 3)
      else
        @opposer_documents = @priority.documents.published.by_opposer_helpfulness.find(:all, :limit => 3)
      end
      document_ids += @opposer_documents.collect {|c| c.id}
    end
    if @priority.neutral_documents_count > 0
      if document_ids.any?
        @neutral_documents = @priority.documents.published.by_neutral_helpfulness.find(:all, :conditions => ["id not in (?)",document_ids], :limit => 3)
      else
        @neutral_documents = @priority.documents.published.by_neutral_helpfulness.find(:all, :limit => 3)
      end
      document_ids += @neutral_documents.collect {|c| c.id}        
    end
    @document_ids = document_ids.uniq.compact    
    
    @activities = @priority.activities.active.for_all_users.by_recently_updated.paginate :include => :user, :page => params[:page]
    if logged_in? and @endorsement
      if @endorsement.is_up?
        @relationships = @priority.relationships.endorsers_endorsed.by_highest_percentage.find(:all, :include => :other_priority).group_by {|o|o.other_priority}
      elsif @endorsement.is_down?
        @relationships = @priority.relationships.opposers_endorsed.by_highest_percentage.find(:all, :include => :other_priority).group_by {|o|o.other_priority}
      end
    else
      @relationships = @priority.relationships.who_endorsed.by_highest_percentage.find(:all, :include => :other_priority).group_by {|o|o.other_priority}
    end
    @endorsements = nil
    if logged_in? # pull all their endorsements on the priorities shown
      @endorsements = Endorsement.find(:all, :conditions => ["priority_id in (?) and user_id = ? and status='active'", @relationships.collect {|other_priority, relationship| other_priority.id},current_user.id])
    end    
    respond_to do |format|
      format.html
      format.xml { render :xml => @priority.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priority.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def opposer_points
    @page_title = t('priorities.opposer_points.title', :priority_name => @priority.name)
    @point_value = -1  
    @points = @priority.points.published.by_opposer_helpfulness.paginate :page => params[:page]  
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def endorser_points
    @page_title = t('priorities.endorser_points.title', :priority_name => @priority.name)
    @point_value = 1
    @points = @priority.points.published.by_endorser_helpfulness.paginate :page => params[:page]
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def neutral_points
    @page_title = t('priorities.neutral_points.title', :priority_name => @priority.name) 
    @point_value = 2 
    @points = @priority.points.published.by_neutral_helpfulness.paginate :page => params[:page]
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def everyone_points
    @page_title = t('priorities.everyone_points.title', :priority_name => @priority.name) 
    @point_value = 0 
    @points = @priority.points.published.by_helpfulness.paginate :page => params[:page]
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:priority, :other_priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def points
    redirect_to :action => "everyone_points"
  end
  
  def documents
    redirect_to :action => "everyone_documents"
  end  
  
  def opposer_documents
    @page_title = t('priorities.opposer_documents.title', :priority_name => @priority.name) 
    @document_value = -1  
    @documents = @priority.documents.published.by_opposer_helpfulness.paginate :page => params[:page]  
    respond_to do |format|
      format.html { render :action => "documents" }
      format.xml { render :xml => @documents.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @documents.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def endorser_documents
    @page_title = t('priorities.endorser_documents.title', :priority_name => @priority.name)   
    @document_value = 1
    @documents = @priority.documents.published.by_endorser_helpfulness.paginate :page => params[:page]
    respond_to do |format|
      format.html { render :action => "documents" }
      format.xml { render :xml => @documents.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @documents.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def neutral_documents
    @page_title = t('priorities.neutral_documents.title', :priority_name => @priority.name)   
    @document_value = 2 
    @documents = @priority.documents.published.by_neutral_helpfulness.paginate :page => params[:page]
    respond_to do |format|
      format.html { render :action => "documents" }
      format.xml { render :xml => @documents.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @documents.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  def everyone_documents
    @page_title = t('priorities.everyone_documents.title', :priority_name => @priority.name) 
    @document_value = 0 
    @documents = @priority.documents.published.by_helpfulness.paginate :page => params[:page]
    respond_to do |format|
      format.html { render :action => "documents" }
      format.xml { render :xml => @documents.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @documents.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def discussions
    @page_title = t('priorities.discussions.title', :priority_name => @priority.name) 
    @activities = @priority.activities.active.discussions.by_recently_updated.for_all_users.paginate :page => params[:page], :per_page => 10
    if @activities.empty? # pull all activities if there are no discussions
      @activities = @priority.activities.active.paginate :page => params[:page]
    end
    respond_to do |format|
      format.html { render :action => "activities" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def comments
    @priority = Priority.find(params[:id])  
    @page_title = t('priorities.comments.title', :priority_name => @priority.name) 
    @comments = Comment.published.by_recently_created.find(:all, :conditions => ["activities.priority_id = ?",@priority.id], :include => :activity).paginate :page => params[:page]
    respond_to do |format|
      format.html
      format.rss { render :template => "rss/comments" }
      format.xml { render :xml => @comments.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @comments.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  # GET /priorities/1/activities
  def activities
    @page_title = t('priorities.activities.title', :priority_name => @priority.name) 
    @activities = @priority.activities.active.for_all_users.by_recently_created.paginate :include => :user, :page => params[:page]
    respond_to do |format|
      format.html
      format.rss { render :template => "rss/activities" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end 
  
  # GET /priorities/1/endorsers
  def endorsers
    @page_title = t('priorities.endorsers.title', :priority_name => @priority.name, :number => @priority.up_endorsements_count)
    if request.format != 'html'
      @endorsements = @priority.endorsements.active_and_inactive.endorsing.paginate :page => params[:page], :include => :user
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @endorsements.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }      
    end
  end

  # GET /priorities/1/opposers
  def opposers
    @page_title = t('priorities.opposers.title', :priority_name => @priority.name, :number => @priority.down_endorsements_count)
    if request.format != 'html'
      @endorsements = @priority.endorsements.active_and_inactive.opposing.paginate :page => params[:page], :include => :user
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @endorsements.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }      
    end
  end

  # GET /priorities/new
  # GET /priorities/new.xml
  def new
    if not params[:q].blank? and not @priorities and current_government.has_search_index?
      @priorities = Priority.search(params[:q])    
    end
    
    @priority = Priority.new unless @priority
  
    if @priorities
      @endorsements = Endorsement.find(:all, :conditions => ["priority_id in (?) and user_id = ? and status='active'", @priorities.collect {|c| c.id},current_user.id])
    end    

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /priorities/1/edit
  def edit
    @priority = Priority.find(params[:id])
    @page_name = t('priorities.edit.title', :priority_name => @priority.name)
    if not (current_user.id == @priority.user_id and @priority.endorsements_count < 2) and not current_user.is_admin?
      flash[:error] = t('priorities.change.already_active')
      redirect_to @priority and return
    end
    respond_to do |format|
      format.html # new.html.erb
    end    
  end

  # POST /priorities
  # POST /priorities.xml
  def create
    @tag_names = params[:tag_names]
    @priority = Priority.new
    @priority.name = params[:q] if params[:q]
    if not logged_in?
      flash[:notice] = t('priorities.new.need_account', :target => current_government.target)
      session[:query] = params[:priority][:name] if params[:priority]
      access_denied
      return
    end
    # if they've confirmed, skip everything and just add it
    if not params[:finalized].blank?
      @priority = Priority.new
      @priority.name = params[:finalized].strip
      @priority.user = current_user
      @priority.ip_address = request.remote_ip
      @saved = @priority.save
    else
      # see if it already exists
      query = params[:priority][:name].strip
      if query.blank? or query == 'Suggest your priority' or query == 'Add a priority to your list'
        flash[:notice] = t('priorities.new.blank')
        redirect_to request.env["HTTP_REFERER"] || "/"
        return
      end
      @priorities = Priority.find(:all, :conditions => ["name = ? and status = 'published'",query], :order => "endorsements_count desc")
      if @priorities.any?
        @priority = @priorities[0]
        @saved = true
      elsif current_government.has_search_index? # doesn't exist, let's do a search assuming there's an index
        @priorities = Priority.search(query)
        if @priorities.any? # found some matches in search, let's show them and bale out of the rest of this
          @priority = Priority.new(params[:priority])
          get_endorsements
          respond_to do |format|
            format.html { render :action => "new"}
          end
          return
        else
          @saved = false
        end
      end
      if not @saved 
        @priority = Priority.new
        @priority.name = params[:priority][:name].strip
        @priority.user = current_user
        @priority.ip_address = request.remote_ip
        @saved = @priority.save      
      end
    end
    @endorsement = @priority.endorse(current_user,request,current_partner,@referral)
    if current_user.endorsements_count > 24
      session[:endorsement_page] = (@endorsement.position/25).to_i+1
      session[:endorsement_page] -= 1 if @endorsement.position == (session[:endorsement_page]*25)-25
    end    
    #did they also do this in a tag area?
    if @tag_names and @priority.issue_list.empty?
      @priority.issue_list = @tag_names 
      @priority.save
    end
    respond_to do |format|
      if @saved
        format.html { 
          flash[:notice] = t('priorities.new.success', :priority_name => @priority.name)
          if @priority.endorsements_count < 2
            redirect_to(new_priority_point_url(@priority))
          else
            redirect_to(@priority)
          end
        }
        format.js {
          render :update do |page|
            if @priority.endorsements_count < 2
              page.redirect_to new_priority_point_url(@priority)
            else
              page.replace_html 'your_priorities_container', :partial => "priorities/yours"
              page.visual_effect :highlight, 'your_priorities'
              page['right_priority_box'].value = ''
            end
          end
        }        
      else
        format.html { render :action => "new" }
      end
    end
  end

  # POST /priorities/1/endorse
  def endorse
    @value = (params[:value]||1).to_i
    @priority = Priority.find(params[:id])
    if not logged_in?
      session[:priority_id] = @priority.id
      session[:value] = @value
    end
    if not logged_in? and request.xhr? and params[:region] == 'priority_inline' # they are endorsing without an account
      @user = User.new
      @signup = Signup.new
      respond_to do |format|
        format.js {
          render :update do |page|
            page.remove 'priority_' + @priority.id.to_s + '_button_small'
            page.insert_html :after, 'priority_' + @priority.id.to_s, :partial => "endorsements/inline_register"
          end
        }
      end
      return
    elsif not logged_in?
      access_denied
      return
    end
    if @value == 1
      @endorsement = @priority.endorse(current_user,request,current_partner,@referral)
    else
      @endorsement = @priority.oppose(current_user,request,current_partner,@referral)
    end
    if params[:ad_id]    
      @ad = Ad.find(params[:ad_id])
      @ad.vote(current_user,@value,request) if @ad
    else
      @ad = Ad.find_by_priority_id_and_status(@priority.id,'active')
      if @ad and @ad.shown_ads.find_by_user_id(current_user.id)
        @ad.vote(current_user,@value,request) 
      end
    end
    @priority.reload    
    if @value == 1          
      @activity = ActivityEndorsementNew.find_by_priority_id_and_user_id(@priority.id,current_user.id, :order => "created_at desc")
    else
      @activity = ActivityOppositionNew.find_by_priority_id_and_user_id(@priority.id,current_user.id, :order => "created_at desc")
    end
    if current_user.endorsements_count > 24
      session[:endorsement_page] = (@endorsement.position/25).to_i+1
      session[:endorsement_page] -= 1 if @endorsement.position == (session[:endorsement_page]*25)-25
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'priority_left'
            page.replace_html 'priority_' + @priority.id.to_s + "_button",render(:partial => "priorities/button", :locals => {:priority => @priority, :endorsement => @endorsement})
            page.replace_html 'priority_' + @priority.id.to_s + "_position",render(:partial => "endorsements/position", :locals => {:endorsement => @endorsement})            
            page.replace 'endorser_link', render(:partial => "priorities/endorser_link") 
            page.replace 'opposer_link', render(:partial => "priorities/opposer_link")             
            #if @activity
            #  page.insert_html :top, 'activities', render(:partial => "activities/show", :locals => {:activity => @activity, :suffix => "_noself"})
            #end
            #page.insert_html :bottom, 'activity_' + @activity.id.to_s + '_comments', render(:partial => "comments/new_inline", :locals => {:comment => Comment.new, :activity => @activity})
            #page.remove 'comment_link_' + @activity.id.to_s
            #page['comment_content_' + @activity.id.to_s].focus
          elsif params[:region] == 'priority_inline'
            page.select('#priority_' + @priority.id.to_s + "_endorsement_count").each { |item| item.replace(render(:partial => "priorities/endorsement_count", :locals => {:priority => @priority})) }            
            page.select('#priority_' + @priority.id.to_s + "_button_small").each {|item| item.replace(render(:partial => "priorities/button_small", :locals => {:priority => @priority, :endorsement => @endorsement}))}
          elsif params[:region] == 'ad_top' and @ad
            page.replace 'notification_show', render(:partial => "ads/pick")
            page << 'jQuery("#notification_show").corners();'
          end
          page.replace_html 'your_priorities_container', :partial => "priorities/yours"
          page.visual_effect :highlight, 'your_priorities'
        end
      }
    end
  end

  # PUT /priorities/1
  # PUT /priorities/1.xml
  def update
    @priority = Priority.find(params[:id])
    @previous_name = @priority.name
    @page_name = t('priorities.edit.title', :priority_name => @priority.name)
    respond_to do |format|
      if @priority.update_attributes(params[:priority]) and @previous_name != params[:priority][:name]
        # already renamed?
        @activity = ActivityPriorityRenamed.find_by_user_id_and_priority_id(current_user.id,@priority.id)
        if @activity
          @activity.update_attribute(:updated_at,Time.now)
        else
          @activity = ActivityPriorityRenamed.create(:user => current_user, :priority => @priority)
        end
        format.html { 
          flash[:notice] = t('priorities.edit.success', :priority_name => @priority.name)
          redirect_to(@priority)         
        }
        format.js {
          render :update do |page|
            page.select('#priority_' + @priority.id.to_s + '_edit_form').each {|item| item.remove}          
            page.select('#activity_and_comments_' + @activity.id.to_s).each {|item| item.remove}                      
            page.insert_html :top, 'activities', render(:partial => "activities/show", :locals => {:activity => @activity, :suffix => "_noself"})
            page.replace_html 'priority_' + @priority.id.to_s + '_name', render(:partial => "priorities/name", :locals => {:priority => @priority})
            page.visual_effect :highlight, 'priority_' + @priority.id.to_s + '_name'
          end
        }
      else
        format.html { render :action => "edit" }
        format.js {
          render :update do |page|
            page.select('#priority_' + @priority.id.to_s + '_edit_form').each {|item| item.remove}
            page.insert_html :top, 'activities', render(:partial => "priorities/new_inline", :locals => {:priority => @priority})
            page['priority_name'].focus
          end
        }
      end
    end
  end

  # PUT /priorities/1/flag_inappropriate
  def flag_inappropriate
    @priority = Priority.find(params[:id])
    @saved = ActivityPriorityFlag.create(:priority => @priority, :user => current_user, :partner => current_partner)
    respond_to do |format|
      flash[:notice] = t('priorities.change.flagged', :priority_name => @priority.name, :admin_name => current_government.admin_name)
      format.html { redirect_to(@priority) }
    end
  end  
  
  # PUT /priorities/1/bury
  def bury
    @priority = Priority.find(params[:id])
    @priority.bury!
    ActivityPriorityBury.create(:priority => @priority, :user => current_user, :partner => current_partner)
    respond_to do |format|
      flash[:notice] = t('priorities.buried', :priority_name => @priority.name)
      format.html { redirect_to(@priority) }
    end
  end  
  
  # PUT /priorities/1/successful
  def successful
    @priority = Priority.find(params[:id])
    @priority.successful!
    respond_to do |format|
      flash[:notice] = t('priorities.successful', :priority_name => @priority.name)
      format.html { redirect_to(@priority) }
    end
  end  
  
  # PUT /priorities/1/intheworks
  def intheworks
    @priority = Priority.find(params[:id])
    @priority.intheworks!
    respond_to do |format|
      flash[:notice] = t('priorities.intheworks', :priority_name => @priority.name)
      format.html { redirect_to(@priority) }
    end
  end  
  
  # PUT /priorities/1/failed
  def failed
    @priority = Priority.find(params[:id])
    @priority.failed!
    respond_to do |format|
      flash[:notice] = t('priorities.failed', :priority_name => @priority.name)
      format.html { redirect_to(@priority) }
    end
  end  
  
  # PUT /priorities/1/compromised
  def compromised
    @priority = Priority.find(params[:id])
    @priority.compromised!
    respond_to do |format|
      flash[:notice] = t('priorities.compromised', :priority_name => @priority.name)
      format.html { redirect_to(@priority) }
    end
  end  
  
  def endorsed
    @priority = Priority.find(params[:id])
    @endorsement = @priority.endorse(current_user,request,current_partner,@referral)
    redirect_to @priority
  end

  def opposed
    @priority = Priority.find(params[:id])
    @endorsement = @priority.oppose(current_user,request,current_partner,@referral)
    redirect_to @priority    
  end

  # GET /priorities/1/tag
  def tag
    @priority = Priority.find(params[:id])
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'priority_' + @priority.id.to_s + '_tags', render(:partial => "priorities/tag", :locals => {:priority => @priority})
          page['priority_' + @priority.id.to_s + "_issue_list"].focus          
        end        
      }
    end
  end

  # POST /priorities/1/tag
  def tag_save
    @priority = Priority.find(params[:id])
    @priority.update_attributes(params[:priority])    
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'priority_' + @priority.id.to_s + '_tags', render(:partial => "priorities/tag_show", :locals => {:priority => @priority}) 
        end        
      }
    end
  end
  
  # DELETE /priorities/1
  def destroy
    if current_user.is_admin?
      @priority = Priority.find(params[:id])
    else
      @priority = current_user.created_priorities.find(params[:id])
    end
    return unless @priority
    name = @priority.name
    spawn do
      current_government.switch_db
      @priority.destroy
    end
    flash[:notice] = t('priorities.destroy.success', :priority_name => name)
    respond_to do |format|
      format.html {
        redirect_to yours_created_priorities_url
      }    
    end
  end  

  private
  
    def get_endorsements
      @endorsements = nil
      if logged_in? # pull all their endorsements on the priorities shown
        @endorsements = current_user.endorsements.active.find(:all, :conditions => ["priority_id in (?)", @priorities.collect {|c| c.id}])
      end
    end
    
    def load_endorsement
      @priority = Priority.find(params[:id])    
      @endorsement = nil
      if logged_in? # pull all their endorsements on the priorities shown
        @endorsement = @priority.endorsements.active.find_by_user_id(current_user.id)
      end
    end    

    def get_qualities
      if not @points.empty?
        @qualities = nil
        if logged_in? # pull all their qualities on the priorities shown
          @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @points.collect {|c| c.id},current_user.id])
        end      
      end      
    end
    
end
