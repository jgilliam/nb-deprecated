class BranchPrioritiesController < ApplicationController

  before_filter :get_branch

  # GET /branches/1/priorities/top
  def top
    @page_title = t('branch_endorsements.top.title', :branch_name => @branch.name)
    @rss_url = top_branch_priorities_url(:format => 'rss')   
    @priorities = @branch.endorsements.published.top_rank.paginate :include => [:priority, :branch], :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }      
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /branches/1/priorities/rising
  def rising
    @page_title = t('branch_endorsements.rising.title', :branch_name => @branch.name)
    @rss_url = rising_branch_priorities_url(:format => 'rss')           
    @priorities = @branch.endorsements.published.rising.paginate :include => [:priority, :branch], :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  # GET /branches/1/priorities/falling
  def falling
    @page_title = t('branch_endorsements.falling.title', :branch_name => @branch.name)
    @rss_url = falling_branch_priorities_url(:format => 'rss')
    @priorities = @branch.endorsements.published.falling.paginate :include => [:priority, :branch], :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }    
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  # GET /branches/1/priorities/controversial  
  def controversial
    @page_title = t('branch_endorsements.controversial.title', :branch_name => @branch.name)
    @rss_url = controversial_branch_priorities_url(:format => 'rss')       
    @priorities = @branch.endorsements.published.controversial.paginate :include => [:priority, :branch], :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /branches/1/priorities/random
  def random
    @page_title = t('branch_endorsements.random.title', :branch_name => @branch.name)
    if User.adapter == 'postgresql'
      @priorities = @branch.endorsements.published.paginate :order => "RANDOM()", :include => [:priority, :branch], :page => params[:page], :per_page => params[:per_page]
    else
      @priorities = @branch.endorsements.published.paginate :order => "rand()", :include => [:priority, :branch], :page => params[:page], :per_page => params[:per_page]
    end
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }      
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /branches/1/priorities/newest
  def newest
    @page_title = t('branch_endorsements.newest.title', :branch_name => @branch.name)
    @rss_url = newest_branch_priorities_url(:format => 'rss')     
    @priorities = @branch.endorsements.published.newest.paginate :include => [:priority, :branch], :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }      
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  # GET /branches/1/priorities/finished
  def finished
    @page_title = t('branch_endorsements.finished.title', :branch_name => @branch.name)
    @rss_url = finished_branch_priorities_url(:format => 'rss')     
    @priorities = @branch.endorsements.finished.paginate :include => [:priority, :branch], :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'priorities/list_widget_small')) + "');" }      
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  protected
  
    def get_branch
      @branch = Branch.find(params[:branch_id])
    end
    
    def get_endorsements
      @endorsements = nil
      if logged_in? # pull all their endorsements on the priorities shown
        @endorsements = current_user.endorsements.active.find(:all, :conditions => ["priority_id in (?)", @priorities.collect {|c| c.priority_id}])
      end
    end
end
