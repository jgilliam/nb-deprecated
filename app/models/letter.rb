class Letter < ActiveRecord::Base

  named_scope :obama, :conditions => "letters.type = 'ObamaLetter'"
  named_scope :by_recently_created, :order => "letters.created_at desc"
  named_scope :is_public, :conditions => "letters.is_public = 1"
  
  belongs_to :user

  validates_presence_of :content

end

class ObamaLetter < Letter
  
  after_create :add_capital
  
  def add_capital
    ActivityObamaLetter.create(:user => user, :letter => self)
    if not CapitalObamaLetter.find_by_recipient_id(user_id)
      ActivityCapitalObamaLetter.create(:user => user, :letter => self, :capital => CapitalObamaLetter.new(:recipient => user, :amount => 3))
    end
  end
  
end