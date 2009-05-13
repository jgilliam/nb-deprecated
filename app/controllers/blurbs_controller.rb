class BlurbsController < ApplicationController

  before_filter :admin_required

  # GET /blurbs
  # GET /blurbs.xml
  def index
    @blurbs = Blurb.find(:all)
    @page_title = t('blurbs.index', :government_name => current_government.name)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @blurbs }
    end
  end

  # GET /blurbs/new
  # GET /blurbs/new.xml
  def new
    @blurbs = Blurb.find(:all)    
    @blurb = Blurb.new
    @blurb.name = params[:name]
    @blurb.content = Blurb.fetch_default(@blurb.name)
    @page_title = t('blurbs.new.title', :blurb_name => @blurb.name)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @blurb }
    end
  end

  # PUT /blurbs/1/preview
  def preview
    @blurb = Blurb.new(params[:blurb])
    respond_to do |format|
      format.js {
        render :update do |page|
          
        end
      }
    end
  end

  # GET /blurbs/1/edit
  def edit
    @blurbs = Blurb.find(:all)    
    @blurb = Blurb.find(params[:id])
    @page_title = t('blurbs.new.title', :blurb_name => @blurb.name)
  end

  # POST /blurbs
  # POST /blurbs.xml
  def create
    @blurbs = Blurb.find(:all)
    @blurb = Blurb.new(params[:blurb])
    respond_to do |format|
      if @blurb.save
        flash[:notice] = t('blurbs.new.success', :blurb_name => @blurb.name)
        format.html { redirect_to(edit_blurb_url(@blurb)) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /blurbs/1
  # PUT /blurbs/1.xml
  def update
    @blurbs = Blurb.find(:all)    
    @blurb = Blurb.find(params[:id])
    @page_title = @blurb.name.capitalize + " blurb"    
    @saved = @blurb.update_attributes(params[:blurb])
    respond_to do |format|
      if @saved
        flash[:notice] = t('blurbs.new.success', :blurb_name => @blurb.name)
        format.html { redirect_to(edit_blurb_url(@blurb)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /blurbs/1
  # DELETE /blurbs/1.xml
  def destroy
    @blurb = Blurb.find(params[:id])
    name = @blurb.name
    @blurb.destroy
    flash[:notice] = t('blurbs.destroy', :blurb_name => name)
    respond_to do |format|
      format.html { redirect_to(new_blurb_url(:name => name)) }
      format.xml  { head :ok }
    end
  end
  
end
