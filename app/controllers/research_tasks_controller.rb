class ResearchTasksController < ApplicationController
  
  before_filter :login_required, :only => [:points, :documents]
  before_filter :admin_required, :only => [:destroy, :edit, :update]
  
  # GET /research_tasks
  # GET /research_tasks.xml
  def index
    @page_title = t('research_tasks.index.title', :government_name => current_government.name)
    @research_tasks = ResearchTask.unclaimed_first.paginate :page => params[:page]
    @rss_url = url_for(:format => "rss")
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @research_tasks.to_xml(:except => :email) }
      format.rss
    end
  end

  def points
    @page_title = t('research_tasks.points.title')
    if current_user.endorsements_count > 0    
      if current_user.up_endorsements_count > 0 and current_user.down_endorsements_count > 0
        @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.up_points_count = 0) or (priorities.id in (?) and priorities.down_points_count = 0)",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact,current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page]
      elsif current_user.up_endorsements_count > 0
        @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.up_points_count = 0)",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page]
      elsif current_user.down_endorsements_count > 0
        @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.down_points_count = 0)",current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page]
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
      format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
    end 
  end
  
 def documents
   @page_title = t('research_tasks.documents.title')
   if current_user.endorsements_count > 0    
     if current_user.up_endorsements_count > 0 and current_user.down_endorsements_count > 0
       @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.up_documents_count = 0) or (priorities.id in (?) and priorities.down_documents_count = 0)",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact,current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page]
     elsif current_user.up_endorsements_count > 0
       @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.up_documents_count = 0)",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page]
     elsif current_user.down_endorsements_count > 0
       @priorities = Priority.published.top_rank.paginate :conditions => ["(priorities.id in (?) and priorities.down_documents_count = 0)",current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :page => params[:page]
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
     format.xml { render :xml => @priorities.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
     format.json { render :json => @priorities.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
   end
 end  
 
 def contributors
   @row = (params[:page].to_i-1)*25
   @row = 0 if params[:page].to_i <= 1
   @page_title = t('research_tasks.contributors.title', :number => current_government.contributors_count, :briefing_name => current_government.briefing_name)
   @users = User.active.at_least_one_endorsement.contributed.by_revisions.paginate :page => params[:page]
   respond_to do |format|
     format.html
     format.xml { render :xml => @users.to_xml(:except => WH2_CONFIG['api_exclude_fields']) }
     format.json { render :json => @users.to_json(:except => WH2_CONFIG['api_exclude_fields']) }
   end    
 end 

  # GET /research_tasks/1
  # GET /research_tasks/1.xml
  def show
    @research_task = ResearchTask.find(params[:id])
    @page_title = t('research_tasks.show.title', :research_task_name => @research_task.name)
    if @research_task.document
      redirect_to @research_task.document
    else
      redirect_to document_research_task_url(@research_task)
    end
  end

  # GET /research_tasks/new
  # GET /research_tasks/new.xml
  def new
    @page_title = t('research_tasks.new.title')
    @research_task = ResearchTask.new
    @research_task.requester = current_user if logged_in?
    @users = User.active.at_least_one_endorsement.contributed.by_revisions.find(:all, :limit => 10)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @research_task }
    end
  end

  # GET /research_tasks/1/edit
  def edit
    @research_task = ResearchTask.find(params[:id])
  end

  # POST /research_tasks
  # POST /research_tasks.xml
  def create
    @page_title = t('research_tasks.new.title')  
    @research_task = ResearchTask.new(params[:research_task])
    @research_task.requester = current_user if logged_in?
    @users = User.active.at_least_one_endorsement.contributed.by_revisions.find(:all, :limit => 10)    
    respond_to do |format|
      if @research_task.save
        flash[:notice] = t('research_tasks.new.success', :government_name => current_government.name)
        format.html { redirect_to(research_tasks_url) }
        format.xml  { render :xml => @research_task, :status => :created, :location => @research_task }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @research_task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /research_tasks/1
  # PUT /research_tasks/1.xml
  def update
    @research_task = ResearchTask.find(params[:id])

    respond_to do |format|
      if @research_task.update_attributes(params[:research_task])
        flash[:notice] = t('research_tasks.change.success')
        format.html { redirect_to(@research_task) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @research_task.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def document
    @research_task = ResearchTask.find(params[:id])
    redirect_to @research_task.document and return if @research_task.document
    @document = Document.new
    @document.name = @research_task.name
    @document.content = @research_task.content
    @page_title = @research_task.name
    respond_to do |format|
      format.html # new.html.erb
    end
  end  
  
  def document_save
    @research_task = ResearchTask.find(params[:id])        
    @document = Document.new(params[:document])
    @document.user = current_user
    @document.research_task = @research_task
    @saved = @document.save
    respond_to do |format|
      if @saved
        if DocumentRevision.create_from_document(@document.id,request)
          session[:goal] = 'document'
          UserMailer.deliver_research_task_started(@document.user,@research_task,@document)
          @quality = @document.qualities.find_or_create_by_user_id_and_value(current_user.id,1)
          format.html { redirect_to(@document) }
          format.js {
            render :update do |page|
              # commented out because we're currently redirecting to the document page
              # and it just goes straight through the facebook dialog.
              #
              #@activity = ActivityDocumentNew.find_by_document_id(@document.id)
              #if @activity and @activity.fb_template_id
              #  fb_data = @activity.fb_data
              #  fb_data[:content] = auto_link(simple_format(h(fb_data[:content])))
              #  page << "FB.Connect.showFeedDialog(#{@activity.fb_template_id.to_s},#{fb_data.to_json});"
              #end         
              page.redirect_to @document 
            end
          }
        end
      else
        format.html { render :action => "new" }
        format.js {
          render :update do |page|
            page.replace_html 'errors', @document.errors.full_messages.join('<br/>')
          end
        }
      end
    end
  end

  # DELETE /research_tasks/1
  # DELETE /research_tasks/1.xml
  def destroy
    @research_task = ResearchTask.find(params[:id])
    @research_task.destroy

    respond_to do |format|
      format.html { redirect_to(research_tasks_url) }
      format.xml  { head :ok }
    end
  end
end
