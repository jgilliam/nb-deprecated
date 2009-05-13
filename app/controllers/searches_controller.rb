class SearchesController < ApplicationController
  
  def index
    @page_title = t('searches.index.title', :government_name => current_government.name)
    if params[:q]
      query = params[:q]
      @page_title = t('searches.results', :government_name => current_government.name, :query => params[:q])
      @priorities = Priority.search(query, :match_mode => :extended, :page => params[:page], :per_page => 25)
      get_endorsements
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @priorities.to_xml(:except => [:sphinx_index, :user_agent,:ip_address,:referrer]) }
      format.json { render :json => @priorities.to_json(:except => [:sphinx_index, :user_agent,:ip_address,:referrer]) }
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
