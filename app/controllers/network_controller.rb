class NetworkController < ApplicationController
  
  before_filter :login_required, :only => [:find]
  before_filter :admin_required, :only => [:unverified, :deleted, :suspended, :probation, :warnings]
  before_filter :setup, :except => [:partner]
  
  def index
    @page_title = t('network.influential.title', :government_name => current_government.name)
    if current_government.users_count < 100
      @users = User.active.at_least_one_endorsement.by_capital.paginate :page => params[:page], :per_page => params[:per_page]
    else
      @users = User.active.at_least_one_endorsement.by_ranking.paginate :page => params[:page], :per_page => params[:per_page]
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def talkative
    @page_title = t('network.talkative.title', :government_name => current_government.name)
    @users = User.active.by_talkative.paginate :conditions => ["users.id <> ?",current_government.official_user_id], :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def ambassadors
    @page_title = t('network.ambassadors.title', :government_name => current_government.name)
    @users = User.active.by_invites_accepted.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def twitterers
    @page_title = t('network.twitterers.title', :government_name => current_government.name)
    @users = User.active.at_least_one_endorsement.twitterers.by_twitter_count.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  

  def unverified
    @page_title = t('network.unverified.title', :government_name => current_government.name)
    @users = User.pending.by_recently_created.paginate :page => params[:page], :per_page => 100
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @users.to_xml(:include => [:referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def warnings
    @page_title = t('network.warnings.title', :government_name => current_government.name)
    @users = User.warnings.by_recently_loggedin.paginate :page => params[:page], :per_page => 100
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def suspended
    @page_title = t('network.suspended.title', :government_name => current_government.name)
    @users = User.suspended.by_suspended_at.paginate :page => params[:page], :per_page => 100
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @users.to_xml(:include => [:referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def probation
    @page_title = t('network.probation.title', :government_name => current_government.name)
    @users = User.probation.by_probation_at.paginate :page => params[:page], :per_page => 100
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @users.to_xml(:include => [:referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def deleted
    @page_title = t('network.deleted.title', :government_name => current_government.name)
    @users = User.deleted.by_deleted_at.paginate :page => params[:page], :per_page => 100
    respond_to do |format|
      format.html { render :action => "list" }
      format.xml { render :xml => @users.to_xml(:include => [:referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  

  def newest
    @page_title = t('network.newest.title', :government_name => current_government.name)
    @users = User.active.at_least_one_endorsement.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def find
    redirect_to user_contacts_path(current_user)
    return
  end

  def search
    @user = User.find_by_login(params[:user][:login])
    if @user
      redirect_to @user 
    else
      flash[:error] = t('users.missing')
      redirect_to :controller => "network"
    end
  end
  
  def partners
    @partners = Partner.find(:all, :conditions => "picture_id is not null and id not in (1,2,3,20)", :order => "rand()")
    @page_title = t('network.partners.title', :government_name => current_government.name)
    respond_to do |format|
      format.html
      format.xml { render :xml => @partners.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @partners.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  private
  def setup
    @user = User.new
    @row = (params[:page].to_i-1)*25
    @row = 0 if params[:page].to_i <= 1
  end 

end

