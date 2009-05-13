class FacebookController < ApplicationController

  before_filter :login_required
  protect_from_forgery :except => :multiple

  def invite
    @page_title = t('facebook.invite.title', :government_name => current_government.name)
    @user = User.find(current_user.id)
    @facebook_contacts = @user.contacts.active.facebook.collect{|c|c.facebook_uid}
    if facebook_session
      app_users = facebook_session.user.friends_with_this_app
      if app_users.any?
        count = 0
        @users = User.active.find(:all, :conditions => ["facebook_uid in (?)",app_users.collect{|u|u.uid}.uniq.compact])        
        for user in @users
          unless @facebook_contacts.include?(user.facebook_uid)
            count += 1
            current_user.follow(user)
            @facebook_contacts << user.facebook_uid
          end
        end
      end
    end
  end

  # POST /facebook/multiple
  def multiple
    @user = User.find(current_user.id)
    if not params[:ids]
      redirect_to :controller => "network", :action => "find"
      return
    end
    @fb_users = facebook_session.users(params[:ids])
    success = 0
    for fb_user in @fb_users
      @contact = @user.contacts.create(:name => fb_user.name, :facebook_uid => fb_user.uid, :is_from_realname => 1)
      if @contact
        success += 1
        @contact.invite!
        @contact.send!
      end
    end
    if success > 0
      flash[:notice] = t('facebook.invite.success', :number => success)
    end
    redirect_to invited_user_contacts_path(current_user)
  end

end
