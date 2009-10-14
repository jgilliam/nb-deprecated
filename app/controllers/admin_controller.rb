class AdminController < ApplicationController
  
  before_filter :admin_required
  
  def random_user
    if User.adapter == 'postgresql'
      users = User.find(:all, :conditions => "status = 'active'", :order => "RANDOM()", :limit => 1)
    else
      users = User.find(:all, :conditions => "status = 'active'", :order => "rand()", :limit => 1)
    end
    self.current_user = users[0]
    flash[:notice] = t('admin.impersonate', :user_name => users[0].name)
    redirect_to users[0]    
  end

  def picture
    @page_title = t('admin.logo', :government_name => current_government.name)
  end

  def picture_save
    @government = current_government
    respond_to do |format|
      if @government.update_attributes(params[:government])
        flash[:notice] = t('pictures.success')
        format.html { redirect_to(:action => :picture) }
      else
        format.html { render :action => "picture" }
      end
    end
  end

  def fav_icon
    @page_title = t('admin.fav_icon', :government_name => current_government.name)
  end

  def fav_icon_save
    @government = current_government
    respond_to do |format|
      if @government.update_attributes(params[:government])
        flash[:notice] = t('pictures.success')
        format.html { redirect_to(:action => :fav_icon) }
      else
        format.html { render :action => "fav_icon" }
      end
    end
  end
  
  def buddy_icon
    @page_title = t('admin.buddy_icon', :government_name => current_government.name)
  end

  def buddy_icon_save
    @government = current_government
    respond_to do |format|
      if @government.update_attributes(params[:government])
        flash[:notice] = t('pictures.success')
        format.html { redirect_to(:action => :buddy_icon) }
      else
        format.html { render :action => "buddy_icon" }
      end
    end
  end  

end
