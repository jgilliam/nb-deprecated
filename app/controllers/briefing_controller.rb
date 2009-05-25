class BriefingController < ApplicationController

  def index
    redirect_to newest_points_url
  end
  
   def points
     @page_title = t('briefing.points.title')
     if current_user.endorsements_count > 0    
       if current_user.up_endorsements_count > 0 and current_user.down_endorsements_count > 0
         @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.up_points_count = 0) or (priorities.id in (?) and priorities.down_points_count = 0)",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact,current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page], :per_page => params[:per_page]
       elsif current_user.up_endorsements_count > 0
         @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.up_points_count = 0)",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page], :per_page => params[:per_page]
       elsif current_user.down_endorsements_count > 0
         @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.down_points_count = 0)",current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page], :per_page => params[:per_page]
       end
       @endorsements = nil
       if logged_in? # pull all their endorsements on the priorities shown
         @endorsements = current_user.endorsements.active.find(:all, :conditions => ["priority_id in (?)", @priorities.collect {|c| c.id}])
       end      
     else
       @priorities = nil
     end    
     respond_to do |format|
       format.html
       format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
       format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
     end 
   end

  def documents
    @page_title = t('briefing.documents.title')
    if current_user.endorsements_count > 0    
      if current_user.up_endorsements_count > 0 and current_user.down_endorsements_count > 0
        @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.up_documents_count = 0) or (priorities.id in (?) and priorities.down_documents_count = 0)",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact,current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page], :per_page => params[:per_page]
      elsif current_user.up_endorsements_count > 0
        @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.up_documents_count = 0)",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page], :per_page => params[:per_page]
      elsif current_user.down_endorsements_count > 0
        @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.down_documents_count = 0)",current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page], :per_page => params[:per_page]
      end
      @endorsements = nil
      if logged_in? # pull all their endorsements on the priorities shown
        @endorsements = current_user.endorsements.active.find(:all, :conditions => ["priority_id in (?)", @priorities.collect {|c| c.id}])
      end      
    else
      @priorities = nil
    end    
    respond_to do |format|
      format.html
      format.xml { render :xml => @priorities.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  def contributors
    @row = (params[:page].to_i-1)*25
    @row = 0 if params[:page].to_i <= 1
    @page_title = t('briefing.contributors.title', :number => current_government.contributors_count, :briefing_name => current_government.briefing_name)
    @users = User.active.at_least_one_endorsement.contributed.by_revisions.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
end
