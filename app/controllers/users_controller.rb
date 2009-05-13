class UsersController < ApplicationController

  before_filter :login_required, :only => [:resend_activation, :follow, :unfollow, :endorse]
  before_filter :current_user_required, :only => [:resend_activation]
  before_filter :admin_required, :only => [:suspend, :unsuspend, :impersonate, :edit, :update, :signups, :legislators, :legislators_save, :make_admin, :reset_password]
  
  def index
    if params[:q]
      @users = User.active.find(:all, :conditions => ["login LIKE ?", "#{h(params[:q])}%"], :order => "users.login asc")
    else
      @users = User.active.by_ranking.paginate :page => params[:page]  
    end
    respond_to do |format|
      format.html { redirect_to :controller => "network" }
      format.js { render :text => @users.collect{|p|p.login}.join("\n") }
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  # render new.rhtml
  def new
    if logged_in?
      redirect_to "/"
      return
    end
    store_previous_location
  end
  
  def edit
    @user = User.find(params[:id])
    check_for_suspension
    @page_title = t('users.edit.title', :user_name => @user.name)
  end
  
  def update
    @user = User.find(params[:id])
    @page_title = t('users.edit.title', :user_name => @user.name)
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = t('users.edit.saved', :user_name => @user.name)
        @page_title = t('users.edit.title', :user_name => @user.name)
        format.html { redirect_to @user }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end  
  
  def signups
    @user = User.find(params[:id])
    check_for_suspension
    @page_title = t('users.signups.title', :user_name => @user.name)
    @rss_url = url_for(:only_path => false, :controller => "rss", :action => "your_notifications", :format => "rss", :c => @user.rss_code)
    @partners = Partner.find(:all, :conditions => "is_optin = 1 and status = 'active' and id <> 3")
  end
  
  def legislators
    @user = User.find(params[:id])
    check_for_suspension
    @page_title = t('users.legislators.title', :user_name => @user.name)
    respond_to do |format|
      format.html
    end    
  end
  
  def legislators_save
    @user = User.find(params[:id])
    @saved = @user.update_attributes(params[:user])  
    @number = @user.attach_legislators if @saved
    if (@saved and @number == 3) or (@saved and @number == 2 and @user.state == 'Minnesota')
      if not CapitalLegislatorsAdded.find_by_recipient_id(@user.id)
        ActivityCapitalLegislatorsAdded.create(:user => @user, :capital => CapitalLegislatorsAdded.create(:recipient => @user, :amount => 2))
      end
    end
    respond_to do |format|
      if @saved
        format.js {
          render :update do |page|
            page.replace_html 'your_legislators', render(:partial => "settings/legislators", :locals => {:user => @user})
            if @number == 3 or (@number == 2 and @user.state == 'Minnesota')
              page.insert_html :top, 'your_legislators', "<div class='red'>" + t('settings.legislators.found_all') + "</div>"
            elsif @number == 2
              page.insert_html :top, 'your_legislators', "<div class='red'>" + t('settings.legislators.found_senators') + "</div>"
            else
              page.insert_html :top, 'your_legislators', "<div class='red'>" + t('settings.legislators.found_none') + "</div>"
            end
          end          
        }
        format.html { 
          flash[:notice] = t('settings.legislators.found_all')
          redirect_to(:action => :legislators) 
        }
      else
        format.js {
          render :update do |page|
            page.insert_html :top, 'your_legislators', "<div class='red'>" + t('settings.legislators.error') + "</div>"
          end          
        }
        format.html { render :action => "legislators" }
      end      
    end    
  end  
  
  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])
    check_for_suspension
    redirect_to obama_priorities_url and return if @user.id == current_government.official_user_id
    @page_title = t('users.show.title', :user_name => @user.name, :government_name => current_government.name)
    @priorities = @user.endorsements.active.by_position.find(:all, :include => :priority, :limit => 5)
    @endorsements = nil
    get_following
    if logged_in? # pull all their endorsements on the priorities shown
      @endorsements = Endorsement.find(:all, :conditions => ["priority_id in (?) and user_id = ? and status='active'", @priorities.collect {|c| c.priority_id},current_user.id])
    end    
    @activities = @user.activities.active.by_recently_created.paginate :include => :user, :page => params[:page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @user.to_xml(:methods => [:revisions_count], :include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @user.to_json(:methods => [:revisions_count], :include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def priorities
    @user = User.find(params[:id])    
    check_for_suspension
    @page_title = t('users.priorities.title', :user_name => @user.name.possessive, :government_name => current_government.name)
    @priorities = @user.endorsements.active.by_position.paginate :include => :priority, :page => params[:page]  
    @endorsements = nil
    get_following
    if logged_in? # pull all their endorsements on the priorities shown
      @endorsements = Endorsement.find(:all, :conditions => ["priority_id in (?) and user_id = ? and status='active'", @priorities.collect {|c| c.priority_id},current_user.id])
    end    
    respond_to do |format|
      format.html
      format.xml { render :xml => @priorities.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def activities
    @user = User.find(params[:id])
    check_for_suspension
    get_following
    @page_title = t('users.activities.title', :user_name => @user.name, :government_name => current_government.name)
    @activities = @user.activities.active.by_recently_created.paginate :page => params[:page]
    respond_to do |format|
      format.html # show.html.erb
      format.rss { render :template => "rss/activities" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def comments
    @user = User.find(params[:id])
    check_for_suspension
    @page_title = t('users.comments.title', :user_name => @user.name.possessive, :government_name => current_government.name)
    @comments = @user.comments.published.by_recently_created.find(:all, :include => :activity).paginate :page => params[:page]
    respond_to do |format|
      format.rss { render :template => "rss/comments" }
      format.xml { render :xml => @comments.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @comments.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def discussions
    @user = User.find(params[:id])
    check_for_suspension
    get_following
    @page_title = t('users.discussions.title', :user_name => @user.name.possessive, :government_name => current_government.name)
    @activities = @user.activities.active.discussions.by_recently_created.paginate :page => params[:page]
    respond_to do |format|
      format.html { render :template => "users/activities" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end 
  
  def ads
    @user = User.find(params[:id])
    check_for_suspension
    get_following
    @page_title = t('users.ads.title', :user_name => @user.name.possessive, :government_name => current_government.name)
    @ads = @user.ads.active_first.paginate :page => params[:page]
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @ads.to_xml(:include => :priority, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ads.to_json(:include => :priority, :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def capital
    @user = User.find(params[:id])
    check_for_suspension
    get_following
    @page_title = t('users.capital.title', :user_name => @user.name.possessive, :currency_name => current_government.currency_name.downcase, :government_name => current_government.name)
    @activities = @user.activities.active.capital.by_recently_created.paginate :page => params[:page]
    respond_to do |format|
      format.html {
        render :template => "users/activities"
      }
      format.xml { render :xml => @activities.to_xml(:include => :capital, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :capital, :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def points
    @user = User.find(params[:id])
    check_for_suspension
    get_following
    @page_title = t('users.points.title', :user_name => @user.name.possessive, :government_name => current_government.name)
    @points = @user.points.published.by_recently_created.paginate :page => params[:page]
    if logged_in? and @points.any? # pull all their qualities on the points shown
      @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @points.collect {|c| c.id},current_user.id])
    end    
    respond_to do |format|
      format.html
      format.xml { render :xml => @points.to_xml(:include => [:priority,:other_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:priority,:other_priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def documents
    @user = User.find(params[:id])
    check_for_suspension
    get_following
    @page_title = t('users.documents.title', :user_name => @user.name.possessive, :government_name => current_government.name)
    @documents = @user.documents.published.by_recently_updated.paginate :page => params[:page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @documents.to_xml(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @documents.to_json(:include => [:priority], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def issues
    @user = User.find(params[:id])
    check_for_suspension
    get_following
    @page_title = t('users.issues.title', :tags_name => current_government.tags_name.pluralize.titleize, :user_name => @user.name)
    @issues = @user.issues(500)
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @issues.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @issues.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  def stratml
    @user = User.find(params[:id])
    @page_title = t('users.priorities.title', :user_name => @user.name.possessive, :government_name => current_government.name)
    @tags = @user.issues(500)
    respond_to do |format|
      format.xml # show.html.erb
    end    
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @valid = true
    @user = User.new(params[:user]) 
    @user.request = request
    @user.referral = @referral
    @user.partner_referral = current_partner
    begin
      @user.save! #save first
      rescue ActiveRecord::RecordInvalid
        @valid = false    
    end
    
    if not @valid # if it's not valid, punt on all the rest
      respond_to do |format|
        format.html { 
          render :action => "new" 
        }
        format.js {
          render :update do |page|
            if session[:priority_id]
              page.replace_html 'register_errors_' + session[:priority_id].to_s, error_messages_for(:user)
            else
              page.replace_html 'register_errors', error_messages_for(:user)
            end
          end
        }
      end
      return
    end
    self.current_user = @user # automatically log them in
    
    if current_partner and params[:signup]
      @user.signups << Signup.create(:partner => current_partner, :is_optin => params[:signup][:is_optin], :ip_address => request.remote_ip)
    end
      
    flash[:notice] = t('users.new.success', :government_name => current_government.name)
    if session[:query] 
      send_to_url = "/?q=" + session[:query]
      session[:query] = nil
    else
      send_to_url = session[:return_to] || get_previous_location
    end
    respond_to do |format|
      format.html { 
        session[:goal] = 'signup'
        redirect_back_or_default
      }
      format.js {
        render :update do |page|
          page << "pageTracker._trackPageview('/goal/signup')" if current_government.has_google_analytics?
          page.redirect_to send_to_url
        end
      }
    end      
  end  

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate!
      flash[:notice] = t('users.activate.success')
    end
    if logged_in? and current_government.is_legislators?
      redirect_to legislators_settings_url
    else
      redirect_back_or_default('/')
    end
  end
  
  def resend_activation
    @user = User.find(params[:id])
    check_for_suspension
    @user.resend_activation
    flash[:notice] = t('users.activate.resend', :email => @user.email)
    redirect_back_or_default(url_for(@user))
  end  

  def reset_password
    @user = User.find(params[:id])
    @user.reset_password
    flash[:notice] = t('passwords.new.sent', :email => @user.email)
    redirect_to @user
  end
  
  # POST /users/1/follow
  def follow
    @value = params[:value].to_i
    @user = User.find(params[:id])
    if @value == 1
      @following = current_user.follow(@user)
    else
      @following = current_user.ignore(@user)    
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'user_left'
            page.replace_html 'user_' + @user.id.to_s + "_button",render(:partial => "users/button_small", :locals => {:user => @user, :following => @following})
          end          
        end
      }    
    end  
  end

  # POST /users/1/unfollow
  def unfollow
    @value = params[:value].to_i
    @user = User.find(params[:id])
    if @value == 1
      current_user.unfollow(@user)
    else
      current_user.unignore(@user)    
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'user_left'
            page.replace_html 'user_' + @user.id.to_s + "_button",render(:partial => "users/button_small", :locals => {:user => @user, :following => nil})
          end          
        end
      }    
    end  
  end
  
  # GET /users/1/followers
  def followers
    @user = User.find(params[:id])
    check_for_suspension
    get_following
    @page_title = t('users.followers.title', :user_name => @user.name, :count => @user.followers_count)      
    @followings = @user.followers.up.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html
      format.xml { render :xml => @followings.to_xml(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /users/1/ignorers
  def ignorers
    @user = User.find(params[:id])
    check_for_suspension
    get_following    
    @page_title = t('users.ignorers.title', :user_name => @user.name, :count => @user.ignorers_count)      
    @followings = @user.followers.down.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html { render :action => "followers" }
      format.xml { render :xml => @followings.to_xml(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  # GET /users/1/following
  def following
    @user = User.find(params[:id])
    check_for_suspension
    get_following
    @page_title = t('users.following.title', :user_name => @user.name, :count => @user.followings_count)      
    @followings = @user.followings.up.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html
      format.xml { render :xml => @followings.to_xml(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /users/1/ignoring
  def ignoring
    @user = User.find(params[:id])
    check_for_suspension
    get_following    
    @page_title = t('users.ignoring.title', :user_name => @user.name, :count => @user.ignorings_count)      
    @followings = @user.followings.down.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html { render :action => "following" }
      format.xml { render :xml => @followings.to_xml(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  # this is for loading up more endorsements in the left column
  def endorsements
    session[:endorsement_page] = (params[:page]||1).to_i
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'your_priorities_container', :partial => "priorities/yours"  
        end
      }
    end
  end

  def order
    order = params[:your_priorities]
    order.each_with_index do |id, position|
      if id.any?
        e = Endorsement.find(id)
        new_position = (((session[:endorsement_page]||1)*25)-25)+position + 1
        if e.position != new_position
          e.insert_at(new_position)
        end
      end
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'your_priorities_container', :partial => "priorities/yours"  
        end
      }
    end
  end

  # PUT /users/1/suspend
  def suspend
    @user = User.find(params[:id])
    @user.suspend! 
    redirect_to(@user)
  end

  # PUT /users/1/unsuspend
  def unsuspend
    @user = User.find(params[:id])
    @user.unsuspend! 
    flash[:notice] = t('users.reinstated', :user_name => @user.name)
    redirect_to(@user)
  end

  # this isn't actually used, but the current_user will endorse ALL of this user's priorities
  def endorse
    if not logged_in?
      session[:endorse_user] = params[:id]
      access_denied
      return
    end
    @user = User.find(params[:id])
    for e in @user.endorsements.active
      e.priority.endorse(current_user,request,current_partner,@referral) if e.is_up?
      e.priority.oppose(current_user,request,current_partner,@referral) if e.is_down?      
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.redirect_to user_path(@user)
        end
      }
    end    
  end
  
  def impersonate
    @user = User.find(params[:id])
    self.current_user = @user
    flash[:notice] = t('admin.impersonate', :user_name => @user.name)
    redirect_to @user
    return
  end
  
  def make_admin
    @user = User.find(params[:id])
    @user.is_admin = true
    @user.save_with_validation(false)
    flash[:notice] = t('users.make_admin', :user_name => @user.name)
    redirect_to @user
  end
  
  private
  
    def get_following
      if logged_in?
        @following = @user.followers.find_by_user_id(current_user.id)      
      else
        @following = nil
      end
    end
    
    def check_for_suspension
      if @user.status == 'suspended'
        flash[:error] = t('users.suspended', :user_name => @user.name)
        if logged_in? and current_user.is_admin?
        else
          redirect_to '/' and return
        end
      end
      if @user.status == 'deleted'
        flash[:error] = t('users.deleted')
        redirect_to '/' and return
      end
    end
  
end
