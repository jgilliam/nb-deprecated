class GovernmentsController < ApplicationController

  before_filter :admin_required
  
  def authorized?
    current_user.is_admin? and current_government.id == params[:id]
  end

  # GET /governments/1/edit
  def edit
    @government = Government.find(params[:id])
    @page_title = t('government.settings.title', :government_name => current_government.name)
  end

  # PUT /governments/1
  # PUT /governments/1.xml
  def update
    @government = Government.find(params[:id])
    @page_title = t('government.settings.title', :government_name => current_government.name)
    respond_to do |format|
      if @government.update_attributes(params[:government])
        flash[:notice] = t('government.settings.success', :government_name => current_government.name)
        format.html { redirect_to edit_government_url(current_government) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

end
