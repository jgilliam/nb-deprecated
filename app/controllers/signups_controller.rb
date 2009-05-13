class SignupsController < ApplicationController
  
  before_filter :admin_required, :except => [:new,:create, :edit, :update]
  
  # GET /signups
  # GET /signups.xml
  def index
    @signups = Signup.find(:all)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /signups/1
  # GET /signups/1.xml
  def show
    @signup = Signup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /signups/new
  # GET /signups/new.xml
  def new
    @signup = Signup.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /signups/1/edit
  def edit
    @signup = Signup.find(params[:id])
  end

  # POST /signups
  # POST /signups.xml
  def create
    @signup = Signup.new(params[:signup])
    @signup.ip_address = request.remote_ip
    respond_to do |format|
      if @signup.save
        flash[:notice] = t('signups.saved')
        format.html { redirect_to(@signup) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /signups/1
  # PUT /signups/1.xml
  def update
    @signup = Signup.find(params[:id])

    respond_to do |format|
      if @signup.update_attributes(params[:signup])
        flash[:notice] = t('signups.saved')
        format.html { redirect_to(@signup) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /signups/1
  # DELETE /signups/1.xml
  def destroy
    @signup = Signup.find(params[:id])
    @signup.destroy

    respond_to do |format|
      format.html { redirect_to(signups_url) }
    end
  end
end
