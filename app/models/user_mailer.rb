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
  
  def new_document_revision_to_requester(sender,recipient_name,recipient_email,revision)
    @recipients  = "#{recipient_name} <#{recipient_email}>"
    @from        = "#{Government.current.name} <#{Government.current.email}>"
    headers        "Reply-to" => Government.current.email
    @sent_on     = Time.now
    @content_type = "text/plain"      
    @subject = sender.login + " revised " + revision.document.name
    @body[:root_url] = 'http://' + Government.current.base_url + '/'
    @body[:recipient] = recipient    
    @body[:sender] = sender
    @body[:revision] = revision
    @body[:document] = revision.document
    @body[:recipient_name] = recipient_name
    @body[:recipient_email] = recipient_email
  end  
  
  def research_task_started(sender,research_task,document)
    if research_task.requester
      @body[:recipient_name] = research_task.requester.real_name
      if research_task.requester.has_email?
        @body[:recipient_email] = research_task.requester.email
      else
        @body[:recipient_email] = research_task.requester_email
      end
    else
      @body[:recipient_name] = research_task.requester_name
      @body[:recipient_email] = research_task.requester_email
    end
    @recipients  = "#{@body[:recipient_name]} <#{@body[:recipient_email]}>"
    @from        = "#{Government.current.name} <#{Government.current.email}>"
    headers        "Reply-to" => Government.current.email
    @sent_on     = Time.now
    @content_type = "text/plain"      
    @subject = sender.login + " started research on " + research_task.name
    @body[:root_url] = 'http://' + Government.current.base_url + '/'
    @body[:recipient] = recipient  
    @body[:sender] = sender
    @body[:research_task] = research_task
    @body[:document] = document
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
