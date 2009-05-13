class ProfilesController < ApplicationController

  before_filter :login_required
  
  def authorized?
    @user = User.find(params[:user_id])
    @page_title = t('profiles.new.title', :government_name => current_government.name)
    current_user.is_admin? or @user.id == current_user.id
  end  
  
  # GET /users/1/profile/1
  # GET /users/1/profile/1.xml
  def show
    redirect_to @user
  end

  # GET /profiles/new
  # GET /profiles/new.xml
  def new
    if @user.profile
      redirect_to edit_user_profile_path(@user)
      return
    end
    @profile = Profile.new
    respond_to do |format|
      format.html { render :action => "profiles/edit" }
      format.xml  { render :xml => @profile }
    end
  end

  # GET /profiles/1/edit
  def edit
    @profile = @user.profile
  end

  # POST /profiles
  # POST /profiles.xml
  def create
    @profile = Profile.new(params[:profile])
    @profile.user = current_user
    respond_to do |format|
      if @profile.save
        flash[:notice] = t('profiles.new.success')
        format.html { redirect_to(@user) }
        format.xml  { render :xml => @profile, :status => :created, :location => @user }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @profile.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /profiles/1
  # PUT /profiles/1.xml
  def update
    @profile = @user.profile    
    respond_to do |format|
      if @profile.update_attributes(params[:profile])
        flash[:notice] = t('profiles.new.success')
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @profile.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /profiles/1
  # DELETE /profiles/1.xml
  def destroy
    @user.profile.destroy
    respond_to do |format|
      format.html { redirect_to(profiles_url) }
      format.xml  { head :ok }
    end
  end
  
end
