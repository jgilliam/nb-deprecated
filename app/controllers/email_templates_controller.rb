class EmailTemplatesController < ApplicationController

  before_filter :admin_required

  # GET /email_templates
  # GET /email_templates.xml
  def index
    @templates = EmailTemplate.find(:all)    
    @page_title = t('email_templates.index')
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @email_templates }
    end
  end

  # GET /email_templates/new
  # GET /email_templates/new.xml
  def new
    @templates = EmailTemplate.find(:all)  
    @email_template = EmailTemplate.new
    @email_template.name = params[:name]
    @email_template.content = EmailTemplate.fetch_default(@email_template.name)
    @email_template.subject = EmailTemplate.fetch_subject_default(@email_template.name)    
    @page_title = t('email_templates.new.title', :email_template_name => @email_template.name)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @email_template }
    end
  end

  # GET /email_templates/1/edit
  def edit
    @templates = EmailTemplate.find(:all)      
    @email_template = EmailTemplate.find(params[:id])
    @page_title = t('email_templates.new.title', :email_template_name => @email_template.name)     
  end

  # POST /email_templates
  # POST /email_templates.xml
  def create
    @templates = EmailTemplate.find(:all)  
    @email_template = EmailTemplate.new(params[:email_template])
    @page_title = t('email_templates.new.title', :email_template_name => @email_template.name)  
    respond_to do |format|
      if @email_template.save
        flash[:notice] = t('email_templates.new.success', :email_template_name => @email_template.name)
        format.html { redirect_to(edit_email_template_url(@email_template)) }
        format.xml  { render :xml => @email_template, :status => :created, :location => @email_template }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @email_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /email_templates/1
  # PUT /email_templates/1.xml
  def update
    @templates = EmailTemplate.find(:all) 
    @email_template = EmailTemplate.find(params[:id])
    @page_title = t('email_templates.new.title', :email_template_name => @email_template.name) 
    respond_to do |format|
      if @email_template.update_attributes(params[:email_template])
        flash[:notice] = t('email_templates.new.success', :email_template_name => @email_template.name)
        format.html { redirect_to(edit_email_template_url(@email_template)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @email_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /email_templates/1
  # DELETE /email_templates/1.xml
  def destroy
    @email_template = EmailTemplate.find(params[:id])
    name = @email_template.name
    @email_template.destroy

    respond_to do |format|
      format.html { redirect_to(new_email_template_url(:name => name)) }
      format.xml  { head :ok }
    end
  end
end
