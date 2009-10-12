class DocumentRevisionsController < ApplicationController

  before_filter :get_document
  before_filter :login_required, :only => [:new, :update, :destroy, :edit, :create]
  before_filter :admin_required, :only => [:destroy, :update, :edit]

  # GET /documents/1/revisions
  def index
    redirect_to @document
    return
  end

  # GET /documents/1/revisions/1
  def show
    if @document.is_deleted?
      flash[:error] = t('document.deleted')
      redirect_to @document.priority
      return
    end
    @revision = @document.revisions.find(params[:id])
    @page_title = t('document.revision.show.title', :document_name => @document.name, :user_name => @revision.user.name)
    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  # GET /documents/1/revisions/1/clean
  def clean
    @revision = @document.revisions.find(params[:id])
    @page_title = t('document.revision.show.title', :document_name => @document.name, :user_name => @revision.user.name)
    respond_to do |format|
      format.html # show.html.erb
    end
  end  

  # GET /documents/1/revisions/new
  def new
    @revision = @document.revisions.new
    @revision.content = @document.content
    @revision.value = @document.value    
    @revision.name = @document.name
    @page_title = t('document.revision.new.title', :document_name => @document.name)  
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /documents/1/revisions/1/edit
  def edit
    @revision = @document.revisions.find(params[:id])
  end

  # POST /documents/1/revisions
  def create
    @revision = @document.revisions.new(params[:revision])
    @revision.user = current_user
    respond_to do |format|
      if @revision.save
        @revision.publish!
        # this is all to add a comment with their note
        if params[:comment][:content] and params[:comment][:content].length > 0
          activities = Activity.find(:all, :conditions => ["user_id = ? and type like 'ActivityDocumentRevision%' and created_at > '#{Time.now-5.minutes}'",current_user.id], :order => "created_at desc")
          if activities.any?
            activity = activities[0]
            @comment = activity.comments.new(params[:comment])
            @comment.user = current_user
            @comment.request = request
            if activity.priority
              # if this is related to a priority, check to see if they endorse it
              e = activity.priority.endorsements.active_and_inactive.find_by_user_id(@comment.user.id)
              @comment.is_endorser = true if e and e.is_up?
              @comment.is_opposer = true if e and e.is_down?
            end
            @comment.save_with_validation(false)            
          end
        end
        flash[:notice] = t('document.revision.new.success', :document_name => @document.name)
        format.html { redirect_to(@document) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /documents/1/revisions/1
  def update
    @revision = @document.revisions.find(params[:id])
    respond_to do |format|
      if @revision.update_attributes(params[:revision])
        flash[:notice] = t('document.revision.new.success', :document_name => @document.name)
        format.html { redirect_to(@revision) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /documents/1/revisions/1
  def destroy
    @revision = @document.revisions.find(params[:id])
    @revision.destroy

    respond_to do |format|
      format.html { redirect_to(revisions_url) }
      format.xml  { head :ok }
    end
  end
  
  protected
  def get_document
    @document = Document.find(params[:document_id])
    @priority = @document.priority
  end
  
end
