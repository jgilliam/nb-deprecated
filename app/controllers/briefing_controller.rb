class BriefingController < ApplicationController

  # GET /briefing/search
  def search
    @page_title = t('briefing.search.title', :government_name => current_government.name, :briefing_name => current_government.briefing_name)
    @results = nil
    if params[:bq]
      @page_title = t('briefing.search.results', :briefing_name => current_government.briefing_name, :query => params[:bq])
      query = params[:bq]
      @results = ThinkingSphinx::Search.search(query, :conditions => {:sphinx_index => "-1"}, :match_mode => :extended, :page => params[:page], :per_page => 10)
      @qualities = nil
      if logged_in? and @results.any? # pull all their qualities on the points shown
        @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @results.collect {|c| c.id if c.class == Point},current_user.id])
      end      
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @results.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @results.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end    
  end  
  
end
