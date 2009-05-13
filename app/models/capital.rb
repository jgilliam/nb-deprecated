class Capital < ActiveRecord::Base

  named_scope :recently, :order => "capitals.created_at desc"

  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  has_many :activities, :dependent => :destroy
  
  belongs_to :capitalizable, :polymorphic => true
  
  after_create :update_user_capital
  after_destroy :update_user_capital

  def update_user_capital
    sender.update_capital if sender
    recipient.update_capital if recipient
  end

end

class CapitalPointHelpfulEveryone < Capital
  
  after_create :add_activity
  
  def add_activity
    ActivityCapitalPointHelpfulEveryone.create(:user => recipient, :point => capitalizable, :capital => self)
  end
  
end

class CapitalPointHelpfulOpposers < Capital
  
  after_create :add_activity
  
  def add_activity
    ActivityCapitalPointHelpfulOpposers.create(:user => recipient, :point => capitalizable, :capital => self)
  end
  
end

class CapitalPointHelpfulUndeclareds < Capital
  
  after_create :add_activity
  
  def add_activity
    ActivityCapitalPointHelpfulUndeclareds.create(:user => recipient, :point => capitalizable, :capital => self)
  end
  
end

class CapitalPointHelpfulEndorsers < Capital
  
  after_create :add_activity
  
  def add_activity
    ActivityCapitalPointHelpfulEndorsers.create(:user => recipient, :point => capitalizable, :capital => self)
  end
  
end

class CapitalPointHelpfulDeleted < Capital
  
  after_create :add_activity
  
  def add_activity
    ActivityCapitalPointHelpfulDeleted.create(:user => recipient, :point => capitalizable, :capital => self)
  end  
  
end

class CapitalDocumentHelpfulEveryone < Capital
  
  after_create :add_activity
  
  def add_activity
    ActivityCapitalDocumentHelpfulEveryone.create(:user => recipient, :document => capitalizable, :capital => self)
  end
  
end

class CapitalDocumentHelpfulOpposers < Capital
  
  after_create :add_activity
  
  def add_activity
    ActivityCapitalDocumentHelpfulOpposers.create(:user => recipient, :document => capitalizable, :capital => self)
  end
  
end

class CapitalDocumentHelpfulUndeclareds < Capital
  
  after_create :add_activity
  
  def add_activity
    ActivityCapitalDocumentHelpfulUndeclareds.create(:user => recipient, :document => capitalizable, :capital => self)
  end
  
end

class CapitalDocumentHelpfulEndorsers < Capital
  
  after_create :add_activity
  
  def add_activity
    ActivityCapitalDocumentHelpfulEndorsers.create(:user => recipient, :document => capitalizable, :capital => self)
  end
  
end

class CapitalDocumentHelpfulDeleted < Capital
  
  after_create :add_activity
  
  def add_activity
    ActivityCapitalDocumentHelpfulDeleted.create(:user => recipient, :document => capitalizable, :capital => self)
  end  
  
end

class CapitalTwitterFollowers < Capital
  
  after_create :add_activity
  
  def add_activity
    ActivityCapitalTwitterFollowers.create(:user => recipient, :capital => self)
  end
  
end

class CapitalWarning < Capital
end

class CapitalUserRecruited < Capital
end

class CapitalPartnerUserRecruited < Capital
end

class CapitalFollowers < Capital
end

class CapitalIgnorers < Capital
end

class CapitalObamaLetter < Capital
end

class CapitalAdNew < Capital
end

class CapitalAcquisitionProposal < Capital
end

class CapitalAcquisitionProposalDeleted < Capital
end

class CapitalAcquisitionProposalApproved < Capital
end

class CapitalInactive < Capital  
end

class CapitalLegislatorsAdded < Capital
end