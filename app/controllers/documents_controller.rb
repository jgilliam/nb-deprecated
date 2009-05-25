class DocumentsController < ApplicationController
  
  before_filter :login_required, :only => [:new, :create, :quality, :unquality, :index, :your_priorities, :destroy]
  before_filter :admin_required, :only => [:edit, :update]
 
  def index
    @page_title = t('document.yours.title')
    @documents = Document.published.by_recently_created.paginate :conditions => ["user_id = ?", current_user.id], :include => :priority, :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @documents.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @documents.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def newest
    @page_title = t('document.newest.title')
    @documents = Document.published.by_recently_created.paginate :include => :priority, :page => params[:page], :per_page => params[:per_page]
    @rss_url = url_for :only_path => false, :format => "rss"
    respond_to do |format|
      format.html { render :action => "index" }
      format.rss { render :template => "rss/documents" }      
      format.xml { render :xml => @documents.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @documents.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def your_priorities
    @page_title = t('document.your_priorities.title')
    if current_user.endorsements_count > 0    
      if current_user.up_endorsements_count > 0 and current_user.down_endorsements_count > 0
        @documents = Document.published.by_recently_created.paginate :conditions => ["(documents.priority_id in (?) and documents.endorser_helpful_count > 0) or (documents.priority_id in (?) and documents.opposer_helpful_count > 0)",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact,current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :include => :priority, :page => params[:page], :per_page => params[:per_page]
      elsif current_user.up_endorsements_count > 0
        @documents = Document.published.by_recently_created.paginate :conditions => ["documents.priority_id in (?) and documents.endorser_helpful_count > 0",current_user.endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.uniq.compact], :include => :priority, :page => params[:page], :per_page => params[:per_page]
      elsif current_user.down_endorsements_count > 0
        @documents = Document.published.by_recently_created.paginate :conditions => ["documents.priority_id in (?) and documents.opposer_helpful_count > 0",current_user.endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.uniq.compact], :include => :priority, :page => params[:page], :per_page => params[:per_page]
      end
    else
      @documents = nil
    end
    respond_to do |format|
      format.html { render :action => "index" }
      format.xml { render :xml => @documents.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @documents.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
 
  def revised
    @page_title = t('document.revised.title')
    @revisions = DocumentRevision.published.by_recently_created.find(:all, :include => [{:document => :priority},:user], :conditions => "documents.revisions_count > 1").paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.xml { render :xml => @revisions.to_xml(:include => :document, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @revisions.to_json(:include => :document, :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end 
 
  # GET /documents/1
  def show
    get_document
    if @document.is_deleted?
      flash[:error] = t('document.deleted')
      redirect_to @document.priority and return
    end
    @page_title = @document.name
    @priority = @document.priority
    if logged_in? 
      @quality = @document.qualities.find_by_user_id(current_user.id) 
    else
      @quality = nil
    end
    @documents = nil
    if @priority
      if @priority.down_documents_count > 1 and @document.is_down?
        @documents = @priority.documents.published.down.by_recently_created.find(:all, :conditions => "id <> #{@document.id}", :include => :priority, :limit => 3)
      elsif @priority.up_documents_count > 1 and @document.is_up?
        @documents = @priority.documents.published.up.by_recently_created.find(:all, :conditions => "id <> #{@document.id}", :include => :priority, :limit => 3)
      elsif @priority.neutral_documents_count > 1 and @document.is_neutral?
        @documents = @priority.documents.published.neutral.by_recently_created.find(:all, :conditions => "id <> #{@document.id}", :include => :priority, :limit => 3)        
      end
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @document.to_xml(:include => :priority) }
      format.json { render :json => @document.to_json(:include => :priority) }
    end
  end
  
  # GET /documents/1/activity
  def activity
    get_document
    @page_title = t('document.activity.title', :document_name => @document.name)
    @priority = @document.priority
    if logged_in? 
      @quality = @document.qualities.find_by_user_id(current_user.id) 
    else
      @quality = nil
    end
    @activities = @document.activities.active.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end  

  # GET /documents/1/discussions
  def discussions
    get_document
    @page_title =  t('document.discussions.title', :document_name => @document.name)
    @priority = @document.priority
    if logged_in? 
      @quality = @document.qualities.find_by_user_id(current_user.id) 
    else
      @quality = nil
    end
    @activities = @document.activities.active.discussions.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "activity" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /priorities/1/documents/new
  def new
    load_endorsement
    @document = @priority.documents.new
    @page_title =  t('document.new.title', :priority_name => @priority.name)
    @document.value = @endorsement.value if @endorsement
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def edit
    get_document
    @page_title =  t('document.edit.title', :document_name => @document.name)
    @priority = @document.priority
  end

  # POST /priorities/1/documents
  def create
    @priority = Priority.find(params[:priority_id])    
    @document = @priority.documents.new(params[:document])
    @document.user = current_user
    @saved = @document.save
    respond_to do |format|
      if @saved
        if DocumentRevision.create_from_document(@document.id,request)
          session[:goal] = 'document'
          flash[:notice] = t('document.new.success', :document_name => @document.name)
          if facebook_session
            current_government.switch_db_back if NB_CONFIG['multiple_government_mode'] and not current_government.is_custom_domain?
            flash[:user_action_to_publish] = UserPublisher.create_document(facebook_session, @document, @priority)
            current_government.switch_db if NB_CONFIG['multiple_government_mode'] and not current_government.is_custom_domain?
          end          
          @quality = @document.qualities.find_or_create_by_user_id_and_value(current_user.id,1)
          format.html { redirect_to(@document) }
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /documents/1
  def update
    get_document
    @priority = @document.priority
    respond_to do |format|
      if @document.update_attributes(params[:document])
        flash[:notice] = t('document.new.save', :document_name => @document.name)
        format.html { redirect_to(@document) }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  # POST /documents/1/quality
  def quality
    get_document
    @quality = @document.qualities.find_or_create_by_user_id_and_value(current_user.id,params[:value].to_i)
    @document.reload    
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == "document_detail"
            page.replace_html 'document_' + @document.id.to_s + '_helpful_button', render(:partial => "documents/button", :locals => {:document => @document, :quality => @quality })
            page.replace_html 'document_' + @document.id.to_s + '_helpful_chart', render(:partial => "documents/helpful_chart", :locals => {:document => @document })            
          elsif params[:region] = "document_inline"
            page.replace_html 'document_' + @document.id.to_s + '_quality', render(:partial => "documents/button_small", :locals => {:document => @document, :quality => @quality, :priority => @document.priority}) 
          end
        end        
      }
    end
  end  
  
  # POST /documents/1/unquality
  def unquality
    get_document
    @qualities = @document.qualities.find(:all, :conditions => ["user_id = ?",current_user.id])
    for quality in @qualities
      quality.destroy
    end
    @document.reload
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == "document_detail"
            page.replace_html 'document_' + @document.id.to_s + '_helpful_button', render(:partial => "documents/button", :locals => {:document => @document, :quality => @quality })
            page.replace_html 'document_' + @document.id.to_s + '_helpful_chart', render(:partial => "documents/helpful_chart", :locals => {:document => @document })            
          elsif params[:region] = "document_inline"
            page.replace_html 'document_' + @document.id.to_s + '_quality', render(:partial => "documents/button_small", :locals => {:document => @document, :quality => @quality, :priority => @document.priority}) 
          end          
        end        
      }
    end
  end  
  
  # GET /documents/1/unhide
  def unhide
    get_document
    @priority = @document.priority
    @quality = nil
    if logged_in?
      @quality = @document.qualities.find_by_user_id(current_user.id)
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace 'document_' + @document.id.to_s, render(:partial => "documents/show", :locals => {:document => @document, :quality => @quality})
        end
      }
    end
  end

  # DELETE /documents/1
  def destroy
    get_document
    if @document.user_id != current_user.id and not current_user.is_admin?
      flash[:error] = t('document.destroy.error')
      redirect_to(@document)
      return
    end
    @document.delete!
    ActivityDocumentDeleted.create(:user => current_user, :document => @document)
    respond_to do |format|
      format.html { redirect_to(documents_url) }
    end
  end
  
  private
    def load_endorsement
      @priority = Priority.find(params[:priority_id])    
      @endorsement = nil
      if logged_in? # pull all their endorsements on the priorities shown
        @endorsement = @priority.endorsements.active.find_by_user_id(current_user.id)
      end    
    end  
    
    def get_document
      @document = Document.find(params[:id])
    end
end
