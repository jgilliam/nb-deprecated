class MessagesController < ApplicationController
  
  before_filter :login_required
  before_filter :get_recipient
  
  def index
    @page_title = t('messages.index', :user_name => @user.name)
    @unread_messages = Message.unread.by_oldest_sent.find(:all, :conditions => ["(recipient_id = ? and sender_id = ?) or (sender_id = ? and recipient_id = ?)",@user.id,current_user.id, @user.id, current_user.id])
    @read_messages = Message.read.by_recently_sent.find(:all, :conditions => ["(recipient_id = ? and sender_id = ?) or (sender_id = ? and recipient_id = ?)",@user.id,current_user.id, @user.id, current_user.id]).paginate :page => params[:page]
    for message in @unread_messages
      message.read! if message.recipient_id == current_user.id
    end
    @message = @user.received_messages.new
    respond_to do |format|
      format.html
      format.xml { render :xml => (@unread_messages+@read_messages).to_xml(:include => [:sender, :recipient], :except => WH2_CONFIG['api_exclude_fields']) }
      format.json { render :json => (@unread_messages+@read_messages).to_json(:include => [:sender, :recipient], :except => WH2_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def create
    @message = @user.received_messages.new(params[:message])
    @message.sender = current_user
    if @message.save
      @message.send!      
      respond_to do |format|
        format.html { redirect_to @user }
        format.js {
          render :update do |page|            
            page.insert_html :before, 'user_' + @user.id.to_s + '_message_form', render(:partial => "messages/show", :locals => {:message => @message})
            @message = @user.received_messages.new
            page.replace 'user_' + @user.id.to_s + '_message_form', render(:partial => "messages/form", :locals => {:message => @message})
          end          
        }
      end
    else
      respond_to do |format|
        format.js {
          render :update do |page|
            page["message-form-submit"].enable
            page["message_content"].focus
            for error in @message.errors
              page.replace_html 'message_error', error[0] + ' ' + error[1]
            end
          end
        }
        format.html { render :action => "new" }
      end
    end
  end
  
  private
  def get_recipient
    @user = User.find(params[:user_id])
    if logged_in?
      @following = @user.followers.find_by_user_id(current_user.id)      
    else
      @following = nil
    end    
  end
end
