class BranchUsersController < ApplicationController

  before_filter :get_branch
  before_filter :setup

  def index
    @page_title = t('branch_users.influential.title', :branch_name => @branch.name, :government_name => current_government.name)
    if current_government.users_count < 100
      @users = @branch.users.active.at_least_one_endorsement.by_capital.paginate :page => params[:page], :per_page => params[:per_page]
    else
      @users = @branch.users.active.at_least_one_endorsement.by_ranking.paginate :page => params[:page], :per_page => params[:per_page]
    end
    respond_to do |format|
      format.html { render :template => "network/index" }
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def talkative
    @page_title = t('branch_users.talkative.title', :branch_name => @branch.name, :government_name => current_government.name)
    @users = @branch.users.active.by_talkative.paginate :conditions => ["users.id <> ?",current_government.official_user_id], :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :template => "network/talkative" }
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def ambassadors
    @page_title = t('branch_users.ambassadors.title', :branch_name => @branch.name, :government_name => current_government.name)
    @users = @branch.users.active.by_invites_accepted.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :template => "network/ambassadors" }
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def twitterers
    @page_title = t('branch_users.twitterers.title', :branch_name => @branch.name, :government_name => current_government.name)
    @users = @branch.users.active.at_least_one_endorsement.twitterers.by_twitter_count.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :template => "network/twitterers" }
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def newest
    @page_title = t('branch_users.newest.title', :branch_name => @branch.name, :government_name => current_government.name)
    @users = @branch.users.active.at_least_one_endorsement.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :template => "network/newest" }
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  

  protected
  
    def get_branch
      @branch = Branch.find(params[:branch_id])
    end

    def setup
      @user = User.new
      @row = (params[:page].to_i-1)*25
      @row = 0 if params[:page].to_i <= 1
    end

end
