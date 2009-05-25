class UserContactsController < ApplicationController
  
  before_filter :login_required
  before_filter :get_user
  
  # GET /users/1/contacts
  def index
    @page_title = t('contacts.index.title', :government_name => current_government.name)
    if @user.contacts_members_count > 0
      redirect_to members_user_contacts_path(@user) and return
    elsif @user.contacts_not_invited_count > 0
      redirect_to not_invited_user_contacts_path(@user) and return
    end
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def following
    @page_title = t('contacts.following.title', :government_name => current_government.name)
    unless current_following_ids.empty?
      @users = User.active.by_capital.find(:all, :conditions => ["id in (?)",current_following_ids]).paginate :page => params[:page], :per_page => params[:per_page]
    end
  end
  
  def members
    @page_title = t('contacts.members.title', :government_name => current_government.name)
    @contacts = @user.contacts.active.members.not_following.find :all, :include => :other_user, :order => "users.created_at desc"
    if @contacts.empty?
      redirect_to not_invited_user_contacts_path(@user) and return
    end
  end  
  
  def allies
    @page_title = t('contacts.allies.title', :government_name => current_government.name)
    @allies = current_user.allies(25)
    @users = nil
    if @allies
      @users = User.active.at_least_one_endorsement.find(:all, :conditions => ["id in (?)",@allies.collect{|u|u.id}]).paginate :page => params[:page], :per_page => params[:per_page]
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @users.to_xml(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @users.to_json(:include => [:top_endorsement, :referral, :partner_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end  
  
  def not_invited
    @page_title = t('contacts.not_invited.title', :government_name => current_government.name)
    @contacts = @user.contacts.active.not_members.not_invited
  end
  
  def invited
    @page_title = t('contacts.invited.title', :government_name => current_government.name)
    @contacts = @user.contacts.active.not_members.invited.recently_updated.paginate :page => params[:page], :per_page => params[:per_page]
  end  

  # GET /users/1/contacts/new
  def new
    @page_title = t('contacts.new.title', :government_name => current_government.name)
    @contact = @user.contacts.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /users/1/contacts
  def create
    @contact = @user.contacts.new(params[:user_contact])
    @already_member = User.find(:all, :conditions => ["email = ? and status in ('active','pending','passive')",@contact.email])
    if @already_member.any?
      @already_member = @already_member[0] 
    else
      @already_member = nil
    end
    @existing = @user.contacts.find_by_email(@contact.email) unless @already_member
    respond_to do |format|
      if @already_member
        @user.follow(@already_member)
        format.js {
          render :update do |page|
            page.replace 'status', '<div id="status">' + t('contacts.new.already_member', :user_name => @already_member.login) + '</div>'
            page.visual_effect :fade, 'status', :duration => 3            
            page['user_contact_name'].value = ''
            page['user_contact_email'].value = ''            
            page['user_contact_name'].focus
          end
        }        
      elsif @existing
        format.js {
          render :update do |page|
            page.replace 'status', '<div id="status">' + t('contacts.new.already_invited', :user_name => @contact.name) + '</div>'
            page.visual_effect :fade, 'status', :duration => 3            
            page['user_contact_name'].value = ''
            page['user_contact_email'].value = ''            
            page['user_contact_name'].focus
          end
        }
      elsif @contact.save
        @contact.invite!
        format.html { 
          flash[:notice] = t('contacts.new.invited', :user_name => @contact.name)
          redirect_to(@contact) 
          }
        format.js {
          render :update do |page|
            page.replace 'status', '<div id="status">' + t('contacts.new.invited', :user_name => @contact.name) + '</div>'
            page.visual_effect :fade, 'status', :duration => 3
            page['user_contact_name'].value = ''
            page['user_contact_email'].value = ''            
            page['user_contact_name'].focus
            #if logged_in?
            #  page.insert_html :top, 'contacts', render(:partial => "contacts/item", :locals => { :contact => @contact })
            #  page.visual_effect :highlight, 'contact_item_' + @contact.id.to_s
            #end
            page << "pageTracker._trackPageview('/goal/invitation')" if current_government.has_google_analytics?
          end
        }
      else
        format.html { render :action => "new" }
        format.js {
          render :update do |page|
            page.replace_html 'status', @contact.errors.full_messages.join('<br/>')
            page.visual_effect :fade, 'status', :duration => 3            
          end
        }        
      end
    end
  end
  
  # PUT /users/1/contacts/multiple
  def multiple
    @contacts = @user.contacts.find(:all, :conditions => ['id in (?)',params[:contact_ids]])
    respond_to do |format|
      format.js {
        render :update do |page|
          success = 0
          for contact in @contacts
            contact.invite!
            page.remove 'contact_' + contact.id.to_s
          end
          @user.reload
          if @user.contacts_not_invited_count == 0 # invited all their contacts
            flash[:notice] = t('contacts.multiple.success', :currency_short_name => current_government.currency_short_name, :government_name => current_government.name)
            page.redirect_to invited_user_contacts_path(@user)
          else
            page.hide 'status'            
            page.replace_html 'contacts_not_invited_count', @user.contacts_not_invited_count
            page.visual_effect :highlight, 'contacts_not_invited_count'            
            page.replace_html 'contacts_invited_count', @user.contacts_invited_count
            page.visual_effect :highlight, 'contacts_invited_count'                                    
          end
        end
      }    
    end
  end  
  
  private
  def get_user
    @user = User.find(params[:user_id])
    access_denied unless current_user.id == @user.id
  end

end
