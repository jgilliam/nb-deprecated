class SettingsController < ApplicationController
  
  before_filter :login_required
  before_filter :get_user

  # GET /settings
  def index
    @partners = Partner.find(:all, :conditions => "is_optin = 1 and status = 'active' and id <> 3")
    @page_title = t('settings.index.title', :government_name => current_government.name)
  end

  # PUT /settings
  def update
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = t('settings.saved')
        format.html { 
          redirect_to(settings_url) 
        }
      else
        format.html { render :action => "index" }
      end
    end
  end

  # GET /settings/signups
  def signups
    @page_title = t('settings.notifications.title', :government_name => current_government.name)
    @rss_url = url_for(:only_path => false, :controller => "rss", :action => "your_notifications", :format => "rss", :c => current_user.rss_code)
    @partners = Partner.find(:all, :conditions => "is_optin = 1 and status = 'active' and id <> 3")
  end

  # GET /settings/picture
  def picture
    @page_title = t('settings.picture.title')
  end

  def picture_save
    @user = current_user
    respond_to do |format|
      if @user.update_attributes(params[:user])
        ActivityUserPictureNew.create(:user => @user)   
        flash[:notice] = t('pictures.success')
        format.html { redirect_to(:action => :picture) }
      else
        format.html { render :action => "picture" }
      end
    end
  end
  
  # GET /settings/legislators
  def legislators
    @page_title = t('settings.legislators.title')
    respond_to do |format|
      format.html
    end    
  end  

  # POST /settings/legislators_save
  def legislators_save
    @saved = @user.update_attributes(params[:user])  
    @number = @user.attach_legislators if @saved
    if (@saved and @number == 3) or (@saved and @number == 2 and @user.state == 'Minnesota')
      if not CapitalLegislatorsAdded.find_by_recipient_id(@user.id)
        ActivityCapitalLegislatorsAdded.create(:user => @user, :capital => CapitalLegislatorsAdded.create(:recipient => @user, :amount => 2))
      end
    end
    respond_to do |format|
      if @saved
        format.js {
          render :update do |page|
            page.replace_html 'your_legislators', render(:partial => "settings/legislators", :locals => {:user => @user})
            if @number == 3 or (@number == 2 and @user.state == 'Minnesota')
              page.insert_html :top, 'your_legislators', "<div class='red'>" + t('settings.legislators.found_all') + "</div>"
            elsif @number == 2
              page.insert_html :top, 'your_legislators', "<div class='red'>" + t('settings.legislators.found_senators') + "</div>"
            else
              page.insert_html :top, 'your_legislators', "<div class='red'>" + t('settings.legislators.found_none') + "</div>"
            end
          end          
        }
        format.html { 
          flash[:notice] = t('settings.legislators.found_all')
          redirect_to(:action => :legislators) 
        }
      else
        format.js {
          render :update do |page|
            page.insert_html :top, 'your_legislators', "<div class='red'>" + t('settings.legislators.error') + "</div>"
          end          
        }
        format.html { render :action => "legislators" }
      end      
    end    
  end
  
  def branch_change
    store_previous_location
    @branch = Branch.find(params[:branch_id])
    if @user.branch_id != @branch.id # they changed their branch, need to update the user counts
      @branch.increment!(:users_count)
      @user.branch.decrement!(:users_count)
    end
    @user.branch = @branch
    @user.is_branch_chosen = true
    @user.save_with_validation(false)
    Branch.expire_cache
    flash[:notice] = t('settings.branch_change.success', :branch_name => @branch.name)
    respond_to do |format|
      format.html { redirect_back_or_default }
    end
  end
  
  # GET /settings/delete
  def delete
    @page_title = t('settings.delete.title', :government_name => current_government.name)
  end

  # DELETE /settings
  def destroy
    @user.delete!
    self.current_user.forget_me
    cookies.delete :auth_token
    reset_session    
    flash[:notice] = t('settings.destroy')
    redirect_to "/" and return
  end

  private
  def get_user
    @user = User.find(current_user.id)
  end

end
