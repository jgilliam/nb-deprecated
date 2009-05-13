class LegislatorsController < ApplicationController

  def index
    @page_title = t('legislators.index', :government_name => current_government.name)
    @legislators = Legislator.by_state.paginate :page => params[:page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @legislators.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @legislators.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def show
    @legislator = Legislator.find(params[:id])
    @page_title = t('legislators.show', :legislator_name => @legislator.name, :government_name => current_government.name)
    respond_to do |format|
      format.html 
      format.xml { render :xml => @legislator.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @legislator.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def priorities
    @user = Legislator.find(params[:id]).user
    raise ActiveRecord::RecordNotFound unless @user
    @page_title = t('users.priorities.title', :user_name => @user.name.possessive, :government_name => current_government.name )
    @endorsements = @user.endorsements.active.by_position.paginate :include => :priority, :page => params[:page]
    respond_to do |format|
      format.html 
      format.xml { render :xml => @endorsements.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

end
