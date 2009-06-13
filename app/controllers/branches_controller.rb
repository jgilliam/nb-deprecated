class BranchesController < ApplicationController

  before_filter :admin_required

  # GET /branches
  # GET /branches.xml
  def index
    @page_title = t('branches.index.title', :government_name => current_government.name)
    @branches = Branch.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @branches }
    end
  end

  # GET /branches/new
  # GET /branches/new.xml
  def new
    @page_title = t('branches.new.title')
    @branches = Branch.all    
    @branch = Branch.new
    respond_to do |format|
      format.html { render :action => "edit" }
      format.xml  { render :xml => @branch }
    end
  end

  # GET /branches/1/edit
  def edit
    @branches = Branch.all  
    @branch = Branch.find(params[:id])
    @page_title = t('branches.edit.title', :branch_name => @branch.name)        
  end

  # POST /branches
  # POST /branches.xml
  def create
    @page_title = t('branches.new.title')    
    @branches = Branch.all    
    @branch = Branch.new(params[:branch])
    respond_to do |format|
      if @branch.save
        flash[:notice] = t('branches.new.success', :branch_name => @branch.name)
        format.html { redirect_to(edit_branch_url(@branch)) }
        format.xml  { render :xml => @branch, :status => :created, :location => @branch }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @branch.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /branches/1
  # PUT /branches/1.xml
  def update
    @branches = Branch.all    
    @branch = Branch.find(params[:id])
    @page_title = t('branches.edit.title', :branch_name => @branch.name)        
    respond_to do |format|
      if @branch.update_attributes(params[:branch])
        Branch.expire_cache
        flash[:notice] =  t('branches.new.success', :branch_name => @branch.name)
        format.html { redirect_to(edit_branch_url(@branch)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @branch.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def default
    @branch = Branch.find(params[:id])
    respond_to do |format|
      if current_government.update_attribute(:default_branch_id, @branch.id)
        current_government.update_user_default_branch # need to change the branches of all the users who haven't chosen
        flash[:notice] =  t('branches.default.success', :branch_name => @branch.name)
        format.html { redirect_to(edit_branch_url(@branch)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @branch.errors, :status => :unprocessable_entity }
      end      
    end
  end

  # DELETE /branches/1
  # DELETE /branches/1.xml
  def destroy
    @branch = Branch.find(params[:id])
    name = @branch.name
    @branch.destroy
    flash[:notice] = t('branches.destroy.success', :branch_name => name)
    respond_to do |format|
      format.html { redirect_to(branches_url) }
      format.xml  { head :ok }
    end
  end
  
end
