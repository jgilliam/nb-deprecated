class TagsController < ApplicationController

  before_filter :admin_required
  before_filter :get_all
  
  # GET /tags
  # GET /tags.xml
  def index
    @page_title = t('tags.title', :tags_name => current_government.tags_name.pluralize.titleize)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tags }
    end
  end

  # GET /tags/1
  # GET /tags/1.xml
  def show
    @tag = Tag.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tag }
    end
  end

  # GET /tags/new
  # GET /tags/new.xml
  def new
    @tag = Tag.new
    @page_title = t('tags.new.title', :tags_name => current_government.tags_name)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tag }
    end
  end

  # GET /tags/1/edit
  def edit
    @tag = Tag.find(params[:id])
    @page_title = t('tags.edit.title', :tag_name => @tag.name)  
    respond_to do |format|  
      format.html { render :action => "new" }
    end
  end

  # POST /tags
  # POST /tags.xml
  def create
    @tag = Tag.new(params[:tag])
    @page_title = t('tags.new.title', :tags_name => current_government.tags_name)
    respond_to do |format|
      if @tag.save
        flash[:notice] = t('tags.new.success', :tag_name => @tag.name)
        format.html { redirect_to(new_tag_url) }
        format.xml  { render :xml => @tag, :status => :created, :location => @tag }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tags/1
  # PUT /tags/1.xml
  def update
    @tag = Tag.find(params[:id])
    if @tag.name != params[:tag][:name] 
      # need to redo the cached_issue_list
      redo_cached_issue_list = true
    else
      redo_cached_issue_list = false
    end
    @page_title = t('tags.edit.title', :tag_name => @tag.name)
    respond_to do |format|
      if @tag.update_attributes(params[:tag])
        Tag.expire_cache
        flash[:notice] = t('tags.new.success', :tag_name => @tag.title)
        format.html { redirect_to(edit_tag_url(@tag)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.xml
  def destroy
    @tag = Tag.find(params[:id])
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to(tags_url) }
      format.xml  { head :ok }
    end
  end
  
  def get_all
    @tags = Tag.alphabetical.all
  end
  
  
end
