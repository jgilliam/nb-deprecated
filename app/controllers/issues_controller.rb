class IssuesController < ApplicationController
  
  before_filter :get_tag_names, :except => :index
  before_filter :login_required, :only => [:yours]
      
  def index
    @page_title = current_government.tags_name.pluralize.titleize
    if request.format != 'html'
      @issues = Tag.most_priorities.paginate(:page => params[:page])
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @issues.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @issues.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def show
    @page_title = t('tags.show.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.top_rank.paginate(:page => params[:page])
    get_endorsements    
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end    
  end

  def yours
    @page_title = t('tags.yours.title', :tag_name => @tag_names, :target => current_government.target)
    @priorities = current_user.priorities.tagged_with(@tag_names, :on => :issues).paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end   
  end
  
  def obama
    @page_title = t('tags.obama.title', :tag_name => @tag_names, :official_user_name => current_government.official_user.name.possessive)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.obama_endorsed.top_rank.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end  
  end
  
  def not_obama
    @page_title = t('tags.not_obama.title', :tag_name => @tag_names, :official_user_name => current_government.official_user.name.possessive)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.not_obama.top_rank.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end   
  end
  
  def obama_opposed
    @page_title = t('tags.obama_opposed.title', :tag_name => @tag_names, :official_user_name => current_government.official_user.name)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.obama_opposed.top_rank.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end
  end  

  def rising
    @page_title = t('tags.rising.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.rising.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end
  end
  
  def falling
    @page_title = t('tags.falling.title', :tag_name => @tag_names.titleize, :target => current_government.target)         
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).falling.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end
  end  

  def controversial
    @page_title = t('tags.controversial.title', :tag_name => @tag_names.titleize, :target => current_government.target)       
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.controversial.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end
  end

  def random
    @page_title = t('tags.random.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.random.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end
  end

  def finished
    @page_title = t('tags.finished.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).finished.by_most_recent_status_change.paginate :page => params[:page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end    
  end

  def newest
    @page_title = t('tags.newest.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.newest.paginate :page => params[:page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end
  end
  
  def discussions
    @page_title = t('tags.discussions.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues)
    @activities = Activity.active.discussions.for_all_users.by_recently_updated.find(:all, :conditions => ["priority_id in (?)",@priorities.collect{|p| p.id}]).paginate :page => params[:page], :per_page => 10
    respond_to do |format|
      format.html
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => WH2_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def documents
    @page_title = t('tags.documents.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues)
    @documents = Document.by_helpfulness.find(:all, :conditions => ["priority_id in (?)",@priorities.collect{|p| p.id}]).paginate :page => params[:page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @documents.to_xml(:include => [:priority], :except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @documents.to_json(:include => [:priority], :except => WH2_CONFIG['api_exclude_fields']) }
    end        
  end  
  
  def points
    @page_title = t('tags.points.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues)
    @points = Point.by_helpfulness.find(:all, :conditions => ["priority_id in (?)",@priorities.collect{|p| p.id}]).paginate :page => params[:page]
    @qualities = nil
    if logged_in? and @points.any? # pull all their qualities on the points shown
      @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @points.collect {|c| c.id},current_user.id])
    end    
    respond_to do |format|
      format.html
      format.xml { render :xml => @points.to_xml(:include => [:priority,:other_priority], :except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:priority,:other_priority], :except => WH2_CONFIG['api_exclude_fields']) }
    end
  end
  
  def twitter
    @page_title = t('tags.twitter.title', :tag_name => @tag_names.titleize, :target => current_government.target)
  end
  
  private
  def get_tag_names
    @tag_names = params[:tag_names]
    @priority = Priority.new
    @priority.name = params[:q] if params[:q]    
    @tag = Tag.find_by_name(@tag_names)
  end  
  
  def get_endorsements
    @endorsements = nil
    if logged_in? # pull all their endorsements on the priorities shown
      @endorsements = Endorsement.find(:all, :conditions => ["priority_id in (?) and user_id = ? and status='active'", @priorities.collect {|c| c.id},current_user.id])
    end
  end
  
end
