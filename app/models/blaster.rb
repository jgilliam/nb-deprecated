class Blaster < ActionMailer::Base
  
  def user_newsletter(blast,user)
    setup_email(user)
    @subject = "Getting priorities done at White House 2"
    @body[:blast] = blast
    @body[:endorsements] = user.endorsements.active.top10
  end
  
  def newsletter(blast,user)
    setup_email(user)
    @subject = "Getting priorities done at White House 2"
    @body[:blast] = blast
    #@body[:priorities] = Priority.find :all, :conditions => "status='published' and position > 0", :order => "position asc", :limit => 10
  end
  
  def add_picture(user,tag)
    setup_email(user)
    @subject = tag.name.titleize + ' will be featured on "This Week at White House 2"'
    @body[:tag] = tag
  end  
  
  def alert(user,tag)
    setup_email(user)
    @subject = "The Obama transition team is asking for your ideas on healthcare"
    @body[:tag] = tag
  end  
  
  def basic_blast(blast,user)
    setup_email(user)
    @subject = "White House 2 priority quiz"
    @body[:blast] = blast
  end
  
  def add_legislators(blast,user)
    setup_email(user)
    @subject = "Sync your White House 2 priorities to your members of Congress"
    @body[:blast] = blast
  end  
  
  protected
    def setup_email(user)
      @recipients  = "#{user.real_name.titleize} <#{user.email}>"
      @from        = "#{Government.current.admin_name} <#{Government.current.admin_email}>"
      headers        "Reply-to" => Government.current.admin_email
      @subject     = ""
      @sent_on     = Time.now
      @content_type = "text/plain"      
      @body[:user] = user
      if user.has_partner_referral?
        @body[:root_url] = 'http://' + user.partner_referral.short_name + '.' + Government.current.base_url + '/'
      else
        @body[:root_url] = 'http://' + Government.current.base_url + '/'
      end  
    end  
  
end
