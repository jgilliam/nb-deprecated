class PartnersController < ApplicationController

  before_filter :login_required, :except => :index
  before_filter :admin_required, :only => [:destroy]

  def index
    @page_title = t('partners.new.title', :government_name => current_government.name)
    if logged_in? and current_user.attribute_present?("partner_id")
      redirect_to 'http://' + current_user.partner.short_name + '.' + current_government.base_url + edit_partner_path(current_user.partner)
    elsif logged_in?
      @partner = Partner.new
    else
      store_location
      @user = User.new
    end
  end
  
  def signup
    @signup = Signup.new(:is_optin => true)
  end

  # GET /partners/1
  # GET /partners/1.xml
  def show
    @partner = Partner.find(params[:id])
    @page_title = @partner.name
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @partner.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @partner.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /partners/new
  # GET /partners/new.xml
  def new
    @page_title = t('partners.new.title', :government_name => current_government.name)
    @partner = Partner.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /partners/1/edit
  def edit
    @partner = Partner.find(params[:id])
    @page_title = t('partners.settings.title') 
  end

  # GET /partners/1/email
  def email
    @partner = Partner.find(params[:id])
    @page_title = t('partners.settings.emails')   
  end

  # POST /partners
  # POST /partners.xml
  def create
    @partner = Partner.new(params[:partner])
    @partner.ip_address = request.remote_ip
    @page_title = t('partners.new.title', :government_name => current_government.name)
    respond_to do |format|
      if @partner.save
        @partner.register!
        current_user.update_attribute(:partner_id,@partner.id)
        @partner.activate!
        flash[:notice] = t('partners.new.success')
        session[:goal] = 'partner'
        format.html { redirect_to 'http://' + @partner.short_name + '.' + current_government.base_url + picture_partner_path(@partner)}
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /partners/1
  # PUT /partners/1.xml
  def update
    @partner = Partner.find(params[:id])
    @page_title = t('partners.settings.title')  
    respond_to do |format|
      if @partner.update_attributes(params[:partner])
        flash[:notice] = t('partners.settings.success')
        format.html { 
          if not @partner.has_picture?
            redirect_to picture_partner_path(@partner)
          elsif params[:partner][:name]
            redirect_to :action => "edit"
          else
            redirect_to :action => "email"
          end
        }
      else
        format.html { 
          if params[:partner][:name]
            render :action => "edit" 
          else # send them to the partner email update
            render :action => "email"
          end
        }
      end
    end
  end
  
  def picture
    @partner = Partner.find(params[:id])
    @page_title = t('partners.picture.title')
  end

  def picture_save
    @partner = Partner.find(params[:id])    
    if params[:picture][:picture].blank?
      flash[:error] = t('pictures.blank')
      redirect_to :action => "picture"
      return
    end    
    @picture = Picture.create(params[:picture])
    @partner.picture = @picture
    respond_to do |format|
      if @partner.save
        ActivityPartnerPictureNew.create(:user => current_user, :partner => @partner, :picture => @picture)        
        flash[:notice] = t('pictures.success')
        format.html { redirect_to(:action => :picture) }
      else
        format.html { render :action => "picture" }
      end
    end
  end  

  # DELETE /partners/1
  # DELETE /partners/1.xml
  def destroy
    @partner = Partner.find(params[:id])
    @partner.destroy

    respond_to do |format|
      format.html { redirect_to(partners_url) }
    end
  end
  
end
