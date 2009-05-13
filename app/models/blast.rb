class Blast < ActiveRecord::Base
  
  belongs_to :user
  
  acts_as_state_machine :initial => :pending, :column => :status
  
  state :pending
  state :sent, :enter => :do_send
  state :notsent
  
  event :send do
    transitions :from => [:pending], :to => :sent
  end
  
  event :dont_send do
    transitions :from => [:pending], :to => :notsent
  end
  
  before_create :make_code
  
  private
  def make_code
    self.code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

end

class BlastNewsletter < Blast
  def do_send
    self.sent_at = Time.now    
    Blaster.deliver_newsletter(self,user)
  end
end

class BlastUserNewsletter < Blast
  def do_send
    self.sent_at = Time.now
    Blaster.deliver_user_newsletter(self,user)
  end
end

class BlastAddPicture < Blast
  
  belongs_to :tag
  
  def do_send
    self.sent_at = Time.now    
    Blaster.deliver_add_picture(user,tag)
  end
  
end

class BlastAlert < Blast
  
  belongs_to :tag
  
  def do_send
    self.sent_at = Time.now    
    Blaster.deliver_alert(user,tag)
  end
  
end

class BlastBasic < Blast
  def do_send
    self.sent_at = Time.now
    Blaster.deliver_basic_blast(self,user)
  end
end

class BlastLegislator < Blast
  def do_send
    self.sent_at = Time.now
    Blaster.deliver_add_legislators(self,user)
  end
end