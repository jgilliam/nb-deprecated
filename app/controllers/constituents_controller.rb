class ConstituentsController < ApplicationController

  before_filter :get_legislator

  def index
    @page_title = t('constituents.index', :legislator_name => @legislator.name)
    # this should have an :include => :top_endorsement, but it causes the total_pages to be returned incorrectly
    @constituents = @legislator.users.active.by_capital.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @constituents.to_xml(:include => :top_endorsement, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @constituents.to_json(:include => :top_endorsement, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def show
    @user = User.find(params[:id])
    @page_title = t('constituents.show', :legislator_name => @legislator.name_with_title, :user_name => @user.name)
    respond_to do |format|
      format.html 
      format.xml { render :xml => @user.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @user.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def priorities
    @page_title = t('constituents.priorities', :legislator_name => @legislator.name_with_title.possessive)
    @constituents = @legislator.constituents
    @endorsements = Endorsement.active.find(:all, 
      :select => "endorsements.priority_id, sum((#{Endorsement.max_position+1}-endorsements.position)*endorsements.value) as score, cast((count(*)-sum(endorsements.value))/2 as signed) as opposers_count, cast(count(*)-(count(*)-sum(endorsements.value))/2 as signed) as endorsers_count", 
      :joins => "endorsements INNER JOIN priorities ON priorities.id = endorsements.priority_id", 
      :conditions => ["endorsements.user_id in (?) and endorsements.position <= #{Endorsement.max_position}",@constituents.collect{|c| c.user_id}.uniq.compact], 
      :group => "endorsements.priority_id", :include => :priority,
      :order => "score desc").paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @endorsements.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def get_legislator
    @legislator = Legislator.find(params[:legislator_id])
  end

end
