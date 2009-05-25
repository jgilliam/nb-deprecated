class AdsController < ApplicationController

  before_filter :get_priority
  before_filter :login_required, :only => [:new, :create, :preview, :skip]
  
  # GET /priorities/1/ads
  def index
    @ads = @priority.ads.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    @page_title = t('ads.index.title', :priority_name => @priority.name)
    respond_to do |format|
      format.html { redirect_to priority_url(@priority) }
      format.xml { render :xml => @ads.to_xml(:include => [:user, :priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ads.to_json(:include => [:user, :priority], :except => NB_CONFIG['api_exclude_fields']) }      
    end
  end

  # GET /priorities/1/ads/1
  def show
    @ad = @priority.ads.find(params[:id])
    @page_title = t('ads.show.title', :priority_name => @priority.name)
    @activities = @ad.activities.active.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @ad.to_xml(:include => [:user, :priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ad.to_json(:include => [:user, :priority], :except => NB_CONFIG['api_exclude_fields']) }      
    end
  end

  # GET /priorities/1/ads/new
  def new
    if @priority.position < 26
      flash[:error] = t('ads.new.top25error')
      redirect_to @priority
      return
    end
    @page_title = t('ads.new.title', :priority_name => @priority.name)  
    @ad = @priority.ads.new
    @ad.user = current_user
    @ad.cost = 1
    @ad.show_ads_count = 100
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /priorities/1/ads
  def create
    @ad = @priority.ads.new(params[:ad])
    @ad.user = current_user
    respond_to do |format|
      if @ad.save
        flash[:notice] = t('ads.new.success', :priority_name => @priority.name)
        format.html { redirect_to(priority_ad_path(@priority,@ad)) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def preview
    @ad = @priority.ads.new(params[:ad])
    @ad.user = current_user
    respond_to do |format|    
      format.js {
        render :update do |page|
          #page.replace_html 'ad_preview', render(:partial => "ads/show", :locals => {:ad => @ad, :endorsement => Endorsement.new})
          page.replace_html 'ad_per_user_cost', render(:partial => "ads/per_user_cost", :locals => {:ad => @ad})
          page.replace_html 'ad_ranking', render(:partial => "ads/ranking", :locals => {:ad => @ad})
        end
      }
    end
  end
  
  # POST /priorities/1/ads/1/skip
  def skip
    @ad = @priority.ads.find(params[:id])
    @ad.vote(current_user,-2,request)
    @priority.reload    
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace 'notification_show', render(:partial => "ads/pick")
        end
      }
    end
  end  
  
  protected
  def get_priority
    @priority = Priority.find(params[:priority_id])
    @endorsement = nil
    if logged_in? # pull their endorsement for this priority
      @endorsement = @priority.endorsements.active.find_by_user_id(current_user.id)
    end    
  end
  
end
