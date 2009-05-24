class UserMailer < ActionMailer::Base
  
  # action mailer docs: http://api.rubyonrails.com/classes/ActionMailer/Base.html
  
  def welcome(user)
    @recipients  = "#{user.real_name.titleize} <#{user.email}>"
    @from        = "#{Government.current.admin_name} <#{Government.current.admin_email}>"
    headers        "Reply-to" => Government.current.admin_email
    @sent_on     = Time.now
    @content_type = "text/plain"      
    @subject = EmailTemplate.fetch_subject_liquid("welcome").render({'government' => Government.current, 'user' => user}, :filters => [LiquidFilters])
    @body = EmailTemplate.fetch_liquid("welcome").render({'government' => Government.current, 'user' => user}, :filters => [LiquidFilters])
  end
  
  def invitation(user,sender_name,to_name,to_email)
    @recipients = ""
    @recipients += to_name + ' ' if to_name
    @recipients += '<' + to_email + '>'
    @from        = "#{Government.current.admin_name} <#{Government.current.admin_email}>"
    headers        "Reply-to" => Government.current.admin_email
    @sent_on = Time.now
    @content_type = "text/plain"      
    @subject = EmailTemplate.fetch_subject_liquid("invitation").render({'government' => Government.current, 'user' => user, 'sender_name' => sender_name, 'to_name' => to_name, 'to_email' => to_email}, :filters => [LiquidFilters])    
    @body = EmailTemplate.fetch_liquid("invitation").render({'government' => Government.current, 'user' => user, 'sender_name' => sender_name, 'to_name' => to_name, 'to_email' => to_email}, :filters => [LiquidFilters])    
  end  

  def new_password(user,new_password) 
    setup_notification(user) 
    @subject = EmailTemplate.fetch_subject_liquid("new_password").render({'government' => Government.current, 'user' => user}, :filters => [LiquidFilters])
    @body = EmailTemplate.fetch_liquid("new_password").render({'government' => Government.current, 'user' => user, 'new_password' => new_password}, :filters => [LiquidFilters])
  end  
  
  def notification(n,sender,recipient,notifiable)
    setup_notification(recipient)    
    @subject = EmailTemplate.fetch_subject_liquid(n.class.to_s.underscore).render({'government' => Government.current, 'recipient' => recipient, 'sender' => sender, 'notifiable' => notifiable, 'notification' => n}, :filters => [LiquidFilters])    
    @body = EmailTemplate.fetch_liquid(n.class.to_s.underscore).render({'government' => Government.current, 'recipient' => recipient, 'sender' => sender, 'notifiable' => notifiable, 'notification' => n}, :filters => [LiquidFilters])
  end  
  
  def new_change_vote(sender,recipient,vote)
    setup_notification(recipient)
    @subject = "Your " + Government.current.name + " vote is needed: " + vote.change.priority.name
    @body[:vote] = vote
    @body[:change] = vote.change
    @body[:recipient] = recipient
    @body[:sender] = sender
  end  

  protected
    def setup_notification(user)
      @recipients  = "#{user.real_name.titleize} <#{user.email}>"
      @from        = "#{Government.current.name} <#{Government.current.email}>"
      headers        "Reply-to" => Government.current.email
      @sent_on     = Time.now
      @content_type = "text/plain"      
      @body[:root_url] = 'http://' + Government.current.base_url + '/'
    end    
        
end
