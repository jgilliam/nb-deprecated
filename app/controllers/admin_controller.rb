class AdminController < ApplicationController
  
  before_filter :admin_required
  
  def random_user
    users = User.find(:all, :conditions => "status = 'active'", :order => "rand()", :limit => 1)
    self.current_user = users[0]
    flash[:notice] = t('admin.impersonate', :user_name => users[0].name)
    redirect_to users[0]    
  end

  def picture
    @page_title = t('admin.logo', :government_name => current_government.name)
  end

  def picture_save
    if params[:picture][:picture].blank?
      flash[:error] = t('pictures.blank')
      redirect_to :action => "picture"
      return
    end    
    @picture = Picture.create(params[:picture])
    @government = Government.find(current_government.id)    
    @government.picture = @picture
    respond_to do |format|
      if @government.save
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
    if params[:picture][:picture].blank?
      flash[:error] = t('pictures.blank')
      redirect_to :action => "fav_icon"
      return
    end    
    @picture = Picture.create(params[:picture])
    @government = Government.find(current_government.id)    
    @government.fav_icon = @picture
    respond_to do |format|
      if @government.save
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
    if params[:picture][:picture].blank?
      flash[:error] = t('pictures.blank')
      redirect_to :action => "buddy_icon"
      return
    end    
    @picture = Picture.create(params[:picture])
    @government = Government.find(current_government.id)    
    @government.buddy_icon = @picture
    respond_to do |format|
      if @government.save
        flash[:notice] = t('pictures.success')
        format.html { redirect_to(:action => :buddy_icon) }
      else
        format.html { render :action => "buddy_icon" }
      end
    end
  end    

end
