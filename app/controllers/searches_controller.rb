class SearchesController < ApplicationController
  
  def index
    @page_title = t('searches.index.title', :government_name => current_government.name)
    @priorities = nil
    if params[:q]
      query = params[:q]
      @page_title = t('searches.results', :government_name => current_government.name, :query => query)
      if query.blank?
        flash.now[:error] = t('briefing.search.blank')
      else
        
        @priority_results = Priority.find_by_solr "(" + params[:q] + ") AND is_published:true", :offset => ((params[:page]||1).to_i-1)*25, :limit => 25
        @priorities = @priority_results.docs
        
        @document_results = Document.find_by_solr "(" + params[:q] + ") AND is_published:true", :offset => ((params[:page]||1).to_i-1)*25, :limit => 1
        @documents = @document_results.docs
        
        @point_results = Point.find_by_solr "(" + params[:q] + ") AND is_published:true", :offset => ((params[:page]||1).to_i-1)*25, :limit => 1
        @points = @point_results.docs                

        get_endorsements        
      end
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @priorities.to_xml(:except => [:user_agent,:ip_address,:referrer]) }
      format.json { render :json => @priorities.to_json(:except => [:user_agent,:ip_address,:referrer]) }
    end    
  end
  
  def points
    @page_title = t('briefing.search.points.title', :government_name => current_government.name, :briefing_name => current_government.briefing_name)
    @points = nil
    if params[:q]
      query = params[:q]
      @page_title = t('briefing.search.points.results', :briefing_name => current_government.briefing_name, :query => query)
      if query.blank?
        flash.now[:error] = t('briefing.search.blank')
      else
        @priority_results = Priority.find_by_solr "(" + params[:q] + ") AND is_published:true", :offset => ((params[:page]||1).to_i-1)*25, :limit => 1
        @priorities = @priority_results.docs
        
        @document_results = Document.find_by_solr "(" + params[:q] + ") AND is_published:true", :offset => ((params[:page]||1).to_i-1)*25, :limit => 1
        @documents = @document_results.docs
        
        @point_results = Point.find_by_solr "(" + params[:q] + ") AND is_published:true", :offset => ((params[:page]||1).to_i-1)*25, :limit => 15
        @points = @point_results.docs
        @qualities = nil
        if logged_in? and @points.any? # pull all their qualities on the points shown
          @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @points.collect {|c| c.id if c.class == Point},current_user.id])
        end    
      end  
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @results.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @results.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def documents
    @page_title = t('briefing.search.documents.title', :government_name => current_government.name, :briefing_name => current_government.briefing_name)
    @documents = nil
    if params[:q]
      query = params[:q]
      if query.blank?
        flash.now[:error] = t('briefing.search.blank')
      else      
        @page_title = t('briefing.search.documents.results', :briefing_name => current_government.briefing_name, :query => query)
        @priority_results = Priority.find_by_solr "(" + params[:q] + ") AND is_published:true", :offset => ((params[:page]||1).to_i-1)*25, :limit => 1
        @priorities = @priority_results.docs
        
        @document_results = Document.find_by_solr "(" + params[:q] + ") AND is_published:true", :offset => ((params[:page]||1).to_i-1)*25, :limit => 15
        @documents = @document_results.docs
        
        @point_results = Point.find_by_solr "(" + params[:q] + ") AND is_published:true", :offset => ((params[:page]||1).to_i-1)*25, :limit => 1
        @points = @point_results.docs
      end
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @results.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @results.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  
  private
  def get_endorsements
    @endorsements = nil
    if logged_in? # pull all their endorsements on the priorities shown
      @endorsements = Endorsement.find(:all, :conditions => ["priority_id in (?) and user_id = ? and status='active'", @priorities.collect {|c| c.id},current_user.id])
    end
  end  
end
