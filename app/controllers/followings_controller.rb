class FollowingsController < ApplicationController

  before_filter :login_required
  before_filter :get_user

  # GET /users/1/followings
  def index
    @followings = @user.followings.up.find(:all)
    respond_to do |format|
      format.html
      format.xml { render :xml => @followings.to_xml(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /users/1/followings/1
  def show
    @following = @user.followings.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :xml => @following.to_xml(:include => [:user, :other_user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @following.to_json(:include => [:user, :other_user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /users/1/followings/new
  def new
    @following = @user.followings.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /users/1/followings/1/edit
  def edit
    @following = @user.followings.find(params[:id])
  end

  # POST /users/1/followings
  def create
    @following = @user.followings.new(params[:following])

    respond_to do |format|
      if @following.save
        flash[:notice] = t('following.new.success', :user_name => @following.other_user.name)
        format.html { redirect_to(@following) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /users/1/followings/1
  def update
    @following = @user.followings.find(params[:id])

    respond_to do |format|
      if @following.update_attributes(params[:following])
        flash[:notice] = t('following.new.success', :user_name => @following.other_user.name)
        format.html { redirect_to(@following) }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  # PUT /users/1/followings/multiple
  def multiple
    user_ids = params[:user_ids]
    unless user_ids
      flash[:error] = t('contacts.multiple.blank')
      respond_to do |format|
        format.js {
          render :update do |page|      
            page.redirect_to not_invited_user_contacts_path(@user)
          end
        }
      end
      return
    end
    for user_id in user_ids
      other_user = User.find(user_id)
      following = current_user.follow(other_user)
    end
    @user.reload
    respond_to do |format|
      format.js {
        render :update do |page|
          if @user.contacts_members_count > 0
            for user_id in user_ids
              page.remove 'contact_' + user_id.to_s
            end
            page.hide 'status'            
            page.replace_html 'contacts_members_count', @user.contacts_members_count
            page.visual_effect :highlight, 'contacts_members_count'            
            page.replace_html 'followings_count', @user.followings_count
            page.visual_effect :highlight, 'followings_count'
          else
            page.redirect_to not_invited_user_contacts_path(@user)
          end
        end
      }    
    end
  end  

  # DELETE /users/1/followings/1
  def destroy
    @following = @user.followings.find(params[:id])
    @following.destroy

    respond_to do |format|
      format.html { redirect_to(followings_url) }
      format.xml  { head :ok }
    end
  end
  
  private
  def get_user
    @user = User.find(params[:user_id])
    access_denied unless @user.id == current_user.id or current_user.is_admin?
  end  
  
end
