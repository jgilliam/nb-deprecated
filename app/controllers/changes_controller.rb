class ChangesController < ApplicationController
  
  before_filter :get_priority
  before_filter :login_required, :except => [:index, :show]
  before_filter :admin_required, :only => [:edit, :update, :destroy, :start, :stop, :approve]
  
  # GET /priorities/1/changes
  # GET /priorities/1/changes.xml
  def index
    @changes = Change.find(:all, :conditions => ["priority_id = ? or new_priority_id = ?",@priority.id,@priority.id], :order => "updated_at desc").paginate :page => params[:page]
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @changes.to_xml(:include => [:user, :priority, :new_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @changes.to_json(:include => [:user, :priority, :new_priority], :except => NB_CONFIG['api_exclude_fields']) }      
    end
  end

  # GET /priorities/1/changes/1
  # GET /priorities/1/changes/1.xml
  def show
    @change = @priority.changes.find(params[:id])
    @page_title = t('changes.show.title', :priority_name => @priority.name)
    for a in @change.activities.find(:all, :conditions => "type in ('ActivityCapitalAcquisitionProposal','ActivityPriorityMergeProposal')")
      @activity = a
    end
    if @activity
      @activities = @change.activities.active.by_recently_updated.find(:all, :conditions => "id <> #{@activity.id.to_s}").paginate :page => params[:page]
    else
      @activities = @change.activities.active.by_recently_updated.paginate :page => params[:page]
    end
    @vote = nil
		@vote =  @change.votes.find_by_user_id(current_user.id) if logged_in?
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @change.to_xml(:include => [:user, :priority, :new_priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @change.to_json(:include => [:user, :priority, :new_priority], :except => NB_CONFIG['api_exclude_fields']) }      
    end
  end
  
  def activities
    @change = @priority.changes.find(params[:id])
    @page_title = t('changes.activities.title', :priority_name => @priority.name)
    for a in @change.activities.find(:all, :conditions => "type in ('ActivityCapitalAcquisitionProposal','ActivityPriorityMergeProposal')")
      @activity = a
    end
    if @activity
      @activities = @change.activities.active.by_recently_updated.find(:all, :conditions => "id <> #{@activity.id.to_s}").paginate :page => params[:page]
    else
      @activities = @change.activities.active.by_recently_updated.paginate :page => params[:page]
    end
    respond_to do |format|
      format.html { redirect_to :action => "show" }
      format.xml { render :xml => @activities.to_xml(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => [:user, :comments], :except => NB_CONFIG['api_exclude_fields']) }      
    end    
  end

  # GET /priorities/1/changes/new
  # GET /priorities/1/changes/new.xml
  def new
    @change = @priority.changes.new
    if @priority.has_change?
      flash[:error] = t('changes.new.already_proposed', :priority_name => @priority.change.new_priority.name)
      return
    end
    respond_to do |format|
      format.html # new.html.erb
      format.js {
        render :update do |page|
          page.select('#priority_' + @priority.id.to_s + '_change_form').each {|item| item.remove}
          page.insert_html :top, 'activities', render(:partial => "new_inline", :locals => {:change => @change, :priority => @priority})
          page['change_new_priority_name'].focus
        end        
      }      
    end
  end

  
  # POST /priorities/1/changes
  # POST /priorities/1/changes.xml
  def create
    @change = @priority.changes.new(params[:change])
    @change.user = current_user
    respond_to do |format|
      if @change.save
        flash[:notice] = t('changes.new.success', :priority_name => @change.new_priority.name, :admin_name => current_government.admin_name)
        format.html { redirect_to(priority_change_path(@priority,@change)) }
        format.js {
          render :update do |page|
            page.redirect_to priority_change_path(@priority,@change)
          end
        }
      else
        format.html { render :action => "new" }
        format.js {
          render :update do |page|
            page.replace_html 'change_errors', @change.errors.full_messages.join('<br/>')
          end
        }
      end
    end    
  end
  
  #
  #  ADMIN ONLY METHODS
  #

  # PUT /priorities/1/changes/1/start
  def start
    @change = @priority.changes.find(params[:id])
    spawn do
      current_government.switch_db
      @change.send!
    end    
    flash[:notice] = t('changes.start')
    redirect_to priority_change_path(@priority,@change)
    return
  end
  
  # PUT /priorities/1/changes/1/approve
  def approve
    @change = @priority.changes.find(params[:id])
    spawn do
      current_government.switch_db
      @change.insta_approve!
    end    
    flash[:notice] = t('changes.approve', :currency_name => current_government.currency_name.downcase, :user_name => @change.user.name)
    redirect_to @change.new_priority
    return
  end
  
  # PUT /priorities/1/changes/1/stop  
  def stop
    @change = @priority.changes.find(params[:id])
    @change.dont_send!
    flash[:notice] = t('changes.stop', :currency_name => current_government.currency_name.downcase, :user_name => @change.user.name)
    ActivityPriorityAcquisitionProposalDeleted.create(:change => @change, :priority => @priority, :user => current_user)    
    redirect_to priority_change_path(@priority,@change)
    return
  end
  
  # PUT /priorities/1/changes/1/flip  
  def flip
    @change = @priority.changes.find(params[:id])
    if @change.new_priority.has_change?
      flash[:error] = t('changes.new.already_proposed', :priority_name => @priority.change.new_priority.name)
      redirect_to @change.new_priority
      return
    end
    @change = @change.flip!
    @change.save
    flash[:notice] = t('changes.flip')
    redirect_to priority_change_path(@change.priority,@change)
    return
  end  

  # GET /priorities/1/changes/1/edit
  def edit
    @change = @priority.changes_with_deleted.find(params[:id])
  end

  # PUT /priorities/1/changes/1
  # PUT /priorities/1/changes/1.xml
  def update
    @change = @priority.change_with_deleted.find(params[:id])

    respond_to do |format|
      if @change.update_attributes(params[:change])
        flash[:notice] = t('changes.saved')
        format.html { redirect_to(priority_changes_path(@change)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /priorities/1/changes/1
  # DELETE /priorities/1/changes/1.xml
  def destroy
    @change = @priority.changes_with_deleted.find(params[:id])
    flash[:notice] = t('changes.destroy')
    @change.delete!
    respond_to do |format|
      format.html { redirect_to(changes_url) }
    end
  end
  
  protected
    def get_priority
      @priority = Priority.find(params[:priority_id])
      @endorsement = nil
      if logged_in? # pull all their endorsements on the priorities shown
        @endorsement = @priority.endorsements.active_and_inactive.find_by_user_id(current_user.id)
      end    
    end  
  
end
