class OauthClientsController < ApplicationController
  before_filter :login_required
  
  def index
    @client_applications = current_user.client_applications
    @tokens = current_user.tokens.find :all, :conditions => 'oauth_tokens.invalidated_at is null and oauth_tokens.authorized_at is not null'
  end

  def new
    @client_application = ClientApplication.new
  end

  def create
    @client_application = current_user.client_applications.build(params[:client_application])
    if @client_application.save
      flash[:notice] = t('oath_clients.new.success')
      redirect_to :action => "show", :id => @client_application.id
    else
      render :action => "new"
    end
  end
  
  def show
    @client_application = current_user.client_applications.find(params[:id])
  end

  def edit
    @client_application = current_user.client_applications.find(params[:id])
  end
  
  def update
    @client_application = current_user.client_applications.find(params[:id])
    if @client_application.update_attributes(params[:client_application])
      flash[:notice] = t('oath_clients.update.success')
      redirect_to :action => "show", :id => @client_application.id
    else
      render :action => "edit"
    end
  end

  def destroy
    @client_application = current_user.client_applications.find(params[:id])
    @client_application.destroy
    flash[:notice] = t('oath_clients.destroy')
    redirect_to :action => "index"
  end
end
