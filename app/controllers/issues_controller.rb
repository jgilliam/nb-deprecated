class IssuesController < ApplicationController
  
  before_filter :get_tag_names, :except => :index
  before_filter :check_for_user, :only => [:yours, :yours_finished, :yours_created, :network]
      
  def index
    @page_title = current_government.tags_name.pluralize.titleize
    if request.format != 'html' or current_government.tags_page == 'list'
      @issues = Tag.most_priorities.paginate(:page => params[:page], :per_page => params[:per_page])
    end
    respond_to do |format|
      format.html {
        if current_government.tags_page == 'cloud'
          render :template => "issues/cloud"
        elsif current_government.tags_page == 'list'
          render :template => "issues/index"
        end
      }
      format.xml { render :xml => @issues.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @issues.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def show
    if not @tag
      flash[:error] = t('tags.show.gone', :tags_name => current_government.tags_name.downcase)
      redirect_to "/" and return 
    end
    @page_title = t('tags.show.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.top_rank.paginate(:page => params[:page], :per_page => params[:per_page])
    get_endorsements    
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }            
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  alias :top :show

  def yours
    @page_title = t('tags.yours.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = @user.priorities.tagged_with(@tag_names, :on => :issues).paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements if logged_in?
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }           
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end   
  end

  def yours_finished
    @page_title = t('tags.yours_finished.title', :tag_name => @tag_names.titleize)
    @priorities = @user.finished_priorities.finished.tagged_with(@tag_names, :on => :issues, :order => "priorities.status_changed_at desc").paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }      
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def yours_created
    @page_title = t('tags.yours_created.title', :tag_name => @tag_names.titleize)
    @priorities = @user.created_priorities.tagged_with(@tag_names, :on => :issues).paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements if logged_in?
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }      
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def network
    @page_title = t('tags.network.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @tag_priorities = Priority.published.tagged_with(@tag_names, :on => :issues)
    if @user.followings_count > 0
      @priorities = Endorsement.active.find(:all, 
        :select => "endorsements.priority_id, sum((#{Endorsement.max_position+1}-endorsements.position)*endorsements.value) as score, count(*) as endorsements_number, priorities.*", 
        :joins => "endorsements INNER JOIN priorities ON priorities.id = endorsements.priority_id", 
        :conditions => ["endorsements.user_id in (?) and endorsements.position <= #{Endorsement.max_position} and endorsements.priority_id in (?)",@user.followings.up.collect{|f|f.other_user_id}, @tag_priorities.collect{|p|p.id}], 
        :group => "endorsements.priority_id",       
        :order => "score desc").paginate :page => params[:page]
        if logged_in?
          @endorsements = current_user.endorsements.active.find(:all, :conditions => ["priority_id in (?)", @network_endorsements.collect {|c| c.priority_id}])
        end
    end
    respond_to do |format|
      format.html
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }         
      format.xml { render :xml => @priorities.to_xml(:include => :priority, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:include => :priority, :except => NB_CONFIG['api_exclude_fields']) }
    end   
  end  

  def obama
    @page_title = t('tags.obama.title', :tag_name => @tag_names.titleize, :official_user_name => current_government.official_user.name.possessive)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.obama_endorsed.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }          
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end  
  end
  
  def not_obama
    @page_title = t('tags.not_obama.title', :tag_name => @tag_names.titleize, :official_user_name => current_government.official_user.name.possessive)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.not_obama.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }          
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end   
  end
  
  def obama_opposed
    @page_title = t('tags.obama_opposed.title', :tag_name => @tag_names.titleize, :official_user_name => current_government.official_user.name)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.obama_opposed.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }          
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  def rising
    @page_title = t('tags.rising.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.rising.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }            
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def falling
    @page_title = t('tags.falling.title', :tag_name => @tag_names.titleize, :target => current_government.target)         
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).falling.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }            
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  def controversial
    @page_title = t('tags.controversial.title', :tag_name => @tag_names.titleize, :target => current_government.target)       
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.controversial.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }            
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def random
    @page_title = t('tags.random.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.random.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }            
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def finished
    @page_title = t('tags.finished.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).finished.by_most_recent_status_change.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }            
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def newest
    @page_title = t('tags.newest.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues).published.newest.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }            
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def discussions
    @page_title = t('tags.discussions.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues)
    @activities = Activity.active.discussions.for_all_users.by_recently_updated.find(:all, :conditions => ["priority_id in (?)",@priorities.collect{|p| p.id}]).paginate :page => params[:page], :per_page => params[:per_page], :per_page => 10
    respond_to do |format|
      format.html
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def documents
    @page_title = t('tags.documents.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues)
    @documents = Document.by_helpfulness.find(:all, :conditions => ["priority_id in (?)",@priorities.collect{|p| p.id}]).paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @documents.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @documents.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end        
  end  
  
  def points
    @page_title = t('tags.points.title', :tag_name => @tag_names.titleize, :target => current_government.target)
    @priorities = Priority.tagged_with(@tag_names, :on => :issues)
    @points = Point.by_helpfulness.find(:all, :conditions => ["priority_id in (?)",@priorities.collect{|p| p.id}]).paginate :page => params[:page], :per_page => params[:per_page]
    @qualities = nil
    if logged_in? and @points.any? # pull all their qualities on the points shown
      @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @points.collect {|c| c.id},current_user.id])
    end    
    respond_to do |format|
      format.html
      format.xml { render :xml => @points.to_xml(:include => [:priority,:other_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:priority,:other_priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def twitter
    @page_title = t('tags.twitter.title', :tag_name => @tag_names.titleize, :target => current_government.target)
  end
  
  private
  def get_tag_names
    @tag = Tag.find_by_slug(params[:slug])
    if not @tag
      flash[:error] = I18n.t('tags.show.gone', :tags_name => current_government.tags_name)
      redirect_to "/issues"
      return
    end
    @tag_names = @tag.name
  end  
  
  def get_endorsements
    @endorsements = nil
    if logged_in? # pull all their endorsements on the priorities shown
      @endorsements = Endorsement.find(:all, :conditions => ["priority_id in (?) and user_id = ? and status='active'", @priorities.collect {|c| c.id},current_user.id])
    end
  end
  
  def check_for_user
    if params[:user_id]
      @user = User.find(params[:user_id])
    elsif logged_in?
      @user = current_user
    else
      access_denied and return
    end
  end  
  
end
