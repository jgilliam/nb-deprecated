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

end
