class ObamaLettersController < ApplicationController
  
  before_filter :login_required, :except => :show
  
  # GET /letters/1
  # GET /letters/1.xml
  def show
    @letter = ObamaLetter.find(params[:id])
    @user = @letter.user
    @page_title = t('obama_letters.show.title', :user_name => @user.name.possessive, :target => current_government.target)
    if not @letter.is_public? and not (logged_in? and current_user == @letter.user)
      flash[:error] = t('obama_letters.private', :user_name => @letter.user.name)
      redirect_to @letter.user
      return
    end
    respond_to do |format|
      if logged_in? and current_user == @letter.user
        format.html { render :action => "preview" }
      else
        format.html
      end
    end
  end

  def preview
    @page_title = t('obama_letters.new.title', :target => current_government.target)
    @letter = ObamaLetter.find(params[:id])
    access_denied unless @letter.user == current_user or current_user.is_admin?
    respond_to do |format|
      format.html
    end
  end

  # GET /letters/new
  # GET /letters/new.xml
  def new
    @page_title = t('obama_letters.new.title', :target => current_government.target)    
    @letter = ObamaLetter.new
    @letter.is_public = true
    @draft = render_to_string(:template => "obama_letters/draft", :layout => false)
    @letter.content = @draft
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /letters/1/edit
  def edit
    @letter = ObamaLetter.find(params[:id])
    access_denied unless @letter.user == current_user or current_user.is_admin?
    @draft = render_to_string(:template => "obama_letters/draft", :layout => false)    
    respond_to do |format|
      format.html { render :action => "new" }
    end    
  end
  
  # POST /letters
  # POST /letters.xml
  def create
    @letter = ObamaLetter.new(params[:obama_letter])
    @user = User.find(current_user.id)
    @letter.user = @user
    @validated = @letter.save
    if params[:user] and params[:user][:zip].nil? and not @user.has_zip?
      @validated = false
      flash[:error] = t('users.errors.need_zip')
    elsif params[:user] and params[:user][:zip]
      @user.update_attribute("zip",params[:user][:zip])
    end
    if params[:user] and params[:user][:email].nil? and not @user.has_email?
      @validated = false
      flash[:error] = t('users.errors.need_email')
    elsif params[:user] and params[:user][:email]
      @user.update_attribute("email",params[:user][:email])
    end    
    respond_to do |format|
      if @validated
        format.html { redirect_to(preview_obama_letter_url(@letter)) }
      else
        @draft = render_to_string(:template => "obama_letters/draft", :layout => false)
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /letters/1
  # PUT /letters/1.xml
  def update
    @letter = ObamaLetter.find(params[:id])
    access_denied unless @letter.user == current_user or current_user.is_admin?
    @validated = @letter.update_attributes(params[:obama_letter])
    if params[:user] and params[:user][:zip].nil? and not current_user.has_zip?
      @validated = false
      flash[:error] = t('users.errors.need_zip')
    elsif params[:user] and params[:user][:zip]
      @user = User.find(current_user.id).update_attribute("zip",params[:user][:zip])
    end   
    respond_to do |format|
      if @validated
        format.html { redirect_to(preview_obama_letter_url(@letter)) }
      else
        @draft = render_to_string(:template => "obama_letters/draft", :layout => false)
        format.html { render :action => "edit" }
      end
    end
  end
  
end
