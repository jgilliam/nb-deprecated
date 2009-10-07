class Activity < ActiveRecord::Base

  named_scope :active, :conditions => "activities.status = 'active'"
  named_scope :deleted, :conditions => "activities.status = 'deleted'", :order => "updated_at desc"
  named_scope :for_all_users, :conditions => "is_user_only=false"

  named_scope :discussions, :conditions => "activities.comments_count > 0"
  named_scope :changes, :conditions => "change_id is not null"
  named_scope :points, :conditions => "type like 'ActivityPoint%'", :order => "activities.created_at desc"
  named_scope :points_and_docs, :conditions => "type like 'ActivityPoint%' or type like 'ActivityDocument%'", :order => "activities.created_at desc"
  named_scope :capital, :conditions => "type like '%Capital%'"
  named_scope :interesting, :conditions => "type in ('ActivityPriorityMergeProposal','ActivityPriorityAcquisitionProposal') or comments_count > 0"
  
  named_scope :last_three_days, :conditions => "activities.changed_at > date_add(now(), INTERVAL -3 DAY)"
  named_scope :last_seven_days, :conditions => "activities.changed_at > date_add(now(), INTERVAL -7 DAY)"
  named_scope :last_thirty_days, :conditions => "activities.changed_at > date_add(now(), INTERVAL -30 DAY)"    
  named_scope :last_24_hours, :conditions => "created_at > date_add(now(), INTERVAL -1 DAY)"  
  
  named_scope :by_recently_updated, :order => "activities.changed_at desc"  
  named_scope :by_recently_created, :order => "activities.created_at desc"    
  
  belongs_to :user
  belongs_to :partner
  
  belongs_to :other_user, :class_name => "User", :foreign_key => "other_user_id"
  belongs_to :priority
  belongs_to :activity
  belongs_to :change
  belongs_to :vote
  belongs_to :tag
  belongs_to :point
  belongs_to :revision
  belongs_to :document
  belongs_to :document_revision
  belongs_to :capital
  belongs_to :ad
  
  has_many :comments, :order => "comments.created_at asc", :dependent => :destroy
  has_many :published_comments, :class_name => "Comment", :foreign_key => "activity_id", :conditions => "comments.status = 'published'", :order => "comments.created_at asc"
  has_many :commenters, :through => :published_comments, :source => :user, :select => "DISTINCT users.*"
  has_many :activities, :dependent => :destroy
  has_many :notifications, :as => :notifiable, :dependent => :destroy
  has_many :followings, :class_name => "FollowingDiscussion", :foreign_key => "activity_id", :dependent => :destroy
  has_many :followers, :through => :followings, :source => :user, :select => "DISTINCT users.*"
  
  liquid_methods :name, :id, :first_comment, :last_comment
  
  # docs: http://www.vaporbase.com/postings/stateful_authentication
  acts_as_state_machine :initial => :active, :column => :status

  before_save :update_changed_at
  
  def update_changed_at
    self.changed_at = Time.now unless self.attribute_present?("changed_at")
  end
  
  state :active
  state :deleted, :enter => :do_delete
  
  event :delete do
    transitions :from => :active, :to => :deleted
  end
  
  event :undelete do
    transitions :from => :deleted, :to => :active
  end

  def do_delete
    # go through and mark all the comments as deleted
    for comment in published_comments
      comment.delete!
    end
  end

  cattr_reader :per_page
  @@per_page = 25

  def commenters_count
    comments.count(:group => :user, :order => "count_all desc")
  end  

  def is_official_user?
    return false unless Government.current.has_official?
    user_id == Government.current.official_user_id
  end

  def has_priority?
    attribute_present?("priority_id")
  end
  
  def has_activity?
    attribute_present?("activity_id")
  end
  
  def has_user?
    attribute_present?("user_id")
  end    
  
  def has_other_user?
    attribute_present?("other_user_id")
  end  
  
  def has_point?
    attribute_present?("point_id")
  end
  
  def has_change?
    attribute_present?("change_id")
  end
  
  def has_capital?
    attribute_present?("capital_id")
  end  
  
  def has_revision?
    attribute_present?("revision_id")
  end    
  
  def has_document?
    attribute_present?("document_id")
  end  
  
  def has_document_revision?
    attribute_present?("document_revision_id")
  end  
  
  def has_ad?
    attribute_present?("ad_id") and ad
  end
  
  def has_comments?
    comments_count > 0
  end
  
  def first_comment
    comments.published.first
  end
  
  def last_comment
    comments.published.last
  end
  
end

class ActivityUserNew < Activity
  def name
    I18n.t('activity.user.new.name', :user_name => user.name, :government_name => Government.current.name)
  end
end

# Jerry invited Jonathan to join
class ActivityInvitationNew < Activity
  def name
    if user 
      I18n.t('activity.invitation.new.name', :user_name => user.login)
    else
      I18n.t('activity.invitation.new.name', :user_name => "Someone")
    end
  end
end

# Jonathan accepted Jerry's invitation to join
class ActivityInvitationAccepted < Activity
  def name
    if other_user
      I18n.t('activity.invitation.accepted.name.known', :user_name => user.name, :other_user_name => other_user.name, :government_name => Government.current.name)
    else
      I18n.t('activity.invitation.accepted.name.unknown', :user_name => user.name, :government_name => Government.current.name)
    end
  end  
end

# Jerry recruited Jonathan to White House 2.
class ActivityUserRecruited < Activity
  
  after_create :add_capital
  
  def add_capital
    ActivityCapitalUserRecruited.create(:user => user, :other_user => other_user, :capital => CapitalUserRecruited.new(:recipient => user, :amount => 5))
  end
  
  def name
    I18n.t('activity.user.recruited.name', :user_name => user.name, :other_user_name => other_user.name, :government_name => Government.current.name)
  end
end

class ActivityCapitalUserRecruited < Activity
  def name
    I18n.t('activity.capital.user.recruited.name', :user_name => user.name, :other_user_name => other_user.name, :government_name => Government.current.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)    
  end
end

class ActivityPartnerUserRecruited < Activity
  
  def name
    I18n.t('activity.user.recruited.partner.name', :user_name => user.name, :other_user_name => other_user.name, :government_name => Government.current.name, :partner_url => partner.short_name + '.' + Government.current.base_url)  
  end
  
end

class ActivityCapitalPartnerUserRecruited < Activity
  def name
    I18n.t('activity.capital.partner.user.recruited.name', :user_name => user.name, :other_user_name => other_user.name, :government_name => Government.current.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name, :partner_url => partner.short_name + '.' + Government.current.base_url)      
  end
end

class ActivityPriorityDebut < Activity
  
  def name
    if attribute_present?("position")
      I18n.t('activity.priority.debut.name.known', :priority_name => priority.name, :position => position)
    else
      I18n.t('activity.priority.debut.name.unknown', :priority_name => priority.name)
    end
  end
  
end

class ActivityUserRankingDebut < Activity
  
  def name
    if attribute_present?("position")
      I18n.t('activity.user.debut.name.known', :user_name => user.name, :position => position)
    else
      I18n.t('activity.user.debut.name.unknown', :user_name => user.name)
    end
  end
  
end

class ActivityEndorsementNew < Activity

  def name
    if has_ad?
      if attribute_present?("position")
        I18n.t('activity.endorsement.new.ad.name.known', :user_name => user.name, :priority_name => priority.name, :position => position, :ad_user => ad.user.name.possessive)
      else
        I18n.t('activity.endorsement.new.ad.name.unknown', :user_name => user.name, :priority_name => priority.name, :ad_user => ad.user.name.possessive)
      end      
    else
      if attribute_present?("position")
        I18n.t('activity.endorsement.new.name.known', :user_name => user.name, :priority_name => priority.name, :position => position)
      else
        I18n.t('activity.endorsement.new.name.unknown', :user_name => user.name, :priority_name => priority.name)
      end
    end
  end  
  
end

class ActivityEndorsementDelete < Activity
  def name
    I18n.t('activity.endorsement.delete.name', :user_name => user.name, :priority_name => priority.name)
  end
end

class ActivityOppositionNew < Activity
  
  def name
    if has_ad?
      if attribute_present?("position")
        I18n.t('activity.opposition.new.ad.name.known', :user_name => user.name, :priority_name => priority.name, :position => position, :ad_user => ad.user.name.possessive)
      else
        I18n.t('activity.opposition.new.ad.name.unknown', :user_name => user.name, :priority_name => priority.name, :ad_user => ad.user.name.possessive)
      end      
    else
      if attribute_present?("position")
        I18n.t('activity.opposition.new.name.known', :user_name => user.name, :priority_name => priority.name, :position => position)
      else
        I18n.t('activity.opposition.new.name.unknown', :user_name => user.name, :priority_name => priority.name)
      end
    end
  end  
  
end

class ActivityOppositionDelete < Activity
  def name
    I18n.t('activity.opposition.delete.name', :user_name => user.name, :priority_name => priority.name)
  end
end

class ActivityEndorsementReplaced < Activity
  def name
    I18n.t('activity.endorsement.replaced.name', :user_name => user.name, :priority_name => priority.name, :new_priority_name => change.new_priority.name)
  end  
end

class ActivityEndorsementReplacedImplicit < Activity
  def name
    I18n.t('activity.endorsement.replaced.implicit.name', :user_name => user.name, :priority_name => priority.name, :new_priority_name => change.new_priority.name)
  end
end

class ActivityEndorsementFlipped < Activity
  def name
    I18n.t('activity.endorsement.flipped.name', :user_name => user.name, :priority_name => priority.name, :new_priority_name => change.new_priority.name)    
  end
end

class ActivityEndorsementFlippedImplicit < Activity
  def name
    I18n.t('activity.endorsement.flipped.implicit.name', :user_name => user.name, :priority_name => priority.name, :new_priority_name => change.new_priority.name)    
  end
end

class ActivityOppositionReplaced < Activity
  def name
    I18n.t('activity.opposition.replaced.name', :user_name => user.name, :priority_name => priority.name, :new_priority_name => change.new_priority.name)
  end
end

class ActivityOppositionReplacedImplicit < Activity
  def name
    I18n.t('activity.opposition.replaced.implicit.name', :user_name => user.name, :priority_name => priority.name, :new_priority_name => change.new_priority.name)
  end
end

class ActivityOppositionFlipped < Activity
  def name
    I18n.t('activity.opposition.flipped.name', :user_name => user.name, :priority_name => priority.name, :new_priority_name => change.new_priority.name)    
  end
end

class ActivityOppositionFlippedImplicit < Activity
  def name
    I18n.t('activity.endorsement.flipped.implicit.name', :user_name => user.name, :priority_name => priority.name, :new_priority_name => change.new_priority.name) 
  end
end

class ActivityPartnerNew < Activity
  def name
    I18n.t('activity.partner.new.name', :partner_name => partner.name)
  end
end

class ActivityPriorityNew < Activity
  def name
    I18n.t('activity.priority.new.name', :user_name => user.name, :priority_name => priority.name)     
  end  
end

# [user name] flagged [priority name] as inappropriate.
class ActivityPriorityFlagInappropriate < Activity
  
  def name
    I18n.t('activity.priority.flagged.name', :user_name => user.name, :priority_name => priority.name)     
  end  
  
  validates_uniqueness_of :user_id, :scope => [:priority_id], :message => "You've already flagged this."
  
end

class ActivityPriorityFlag < Activity
  
  def name
    I18n.t('activity.priority.flagged.name', :user_name => user.name, :priority_name => priority.name)  
  end  

  after_create :notify_admin
  
  def notify_admin
    for r in User.active.admins
      priority.notifications << NotificationPriorityFlagged.new(:sender => user, :recipient => r) if r.id != user.id
    end
  end
  
end

# [user name] buried [priority name].
class ActivityPriorityBury < Activity
  def name
    I18n.t('activity.priority.buried.name', :user_name => user.name, :priority_name => priority.name)  
  end
end

# identifies that a person is participating in a discussion about another activity
# is_user_only!  it's not meant to be shown on the priority page, just on the user page
# and it's only supposed to be invoked once, when they first start discussing an activity
# but the updated_at should be updated on subsequent postings in the discussion
class ActivityCommentParticipant < Activity
 
  def name
    I18n.t('activity.comment.participant.name', :user_name => user.name, :count => comments_count, :discussion_name => activity.name)  
  end
  
end

class ActivityDiscussionFollowingNew < Activity
  def name
    I18n.t('activity.discussion.following.new.name', :user_name => user.name, :discussion_name => activity.name)
  end
end

class ActivityDiscussionFollowingDelete < Activity
  def name
    I18n.t('activity.discussion.following.delete.name', :user_name => user.name, :discussion_name => activity.name)
  end
end

class ActivityPriorityCommentNew < Activity
  def name
    I18n.t('activity.priority.comment.new.name', :user_name => user.name, :priority_name => priority.name)  
  end
end

class ActivityBulletinProfileNew < Activity
  
  after_create :send_notification
  
  def send_notification
    notifications << NotificationProfileBulletin.new(:sender => self.other_user, :recipient => self.user)       
  end
  
  def name
    I18n.t('activity.bulletin.profile.new.name', :user_name => other_user.name, :other_user_name => user.name.possessive)  
  end
  
end

class ActivityBulletinProfileAuthor < Activity
  
  def name
    I18n.t('activity.bulletin.profile.new.name', :user_name => user.name, :other_user_name => other_user.name.possessive)      
  end
  
end

class ActivityBulletinNew < Activity
  
  def name
    if point
      I18n.t('activity.bulletin.new.name.known', :user_name => user.name, :discussion_name => point.name)         
    elsif document
      I18n.t('activity.bulletin.new.name.known', :user_name => user.name, :discussion_name => document.name)
    elsif priority
      I18n.t('activity.bulletin.new.name.known', :user_name => user.name, :discussion_name => priority.name)
    else
      I18n.t('activity.bulletin.new.name.unknown', :user_name => user.name)
    end
  end
  
end

class ActivityPriority1 < Activity
  def name
    I18n.t('activity.priority.first.endorsed.name', :user_name => user.name.possessive, :priority_name => priority.name)
  end
end

class ActivityPriority1Opposed < Activity
  def name
    I18n.t('activity.priority.first.opposed.name', :user_name => user.name.possessive, :priority_name => priority.name)
  end
end

class ActivityPriorityRising1 < Activity
  def name
    I18n.t('activity.priority.rising.name', :priority_name => priority.name)
  end
end

class ActivityIssuePriority1 < Activity
  def name
    I18n.t('activity.priority.tag.first.name', :priority_name => priority.name, :tag_name => tag.title)
  end
end

class ActivityIssuePriorityControversial1 < Activity
  def name
    I18n.t('activity.priority.tag.controversial.name', :priority_name => priority.name, :tag_name => tag.title)
  end
end

class ActivityIssuePriorityRising1 < Activity
  def name
    I18n.t('activity.priority.tag.rising.name', :priority_name => priority.name, :tag_name => tag.title)
  end
end

class ActivityIssuePriorityObama1 < Activity
  def name
    I18n.t('activity.priority.tag.obama.first.name', :priority_name => priority.name, :tag_name => tag.title, :official_user_name => Government.current.official_user.name.possessive)    
  end
end

class ActivityPriorityMergeProposal < Activity
  def name
    I18n.t('activity.priority.acquisition.proposal.name', :user_name => user.name, :priority_name => priority.name, :new_priority_name => change.new_priority.name)    
  end
end

class ActivityPriorityRenamed < Activity
  def name
    I18n.t('activity.priority.renamed.name', :user_name => user.name, :priority_name => priority.name)  
  end
end

class ActivityPointNew < Activity
  
  def name
    I18n.t('activity.point.new.name', :user_name => user.name, :point_name => point.name, :priority_name => priority.name)      
  end
  
end

class ActivityPointDeleted < Activity
  def name
    I18n.t('activity.point.deleted.name', :user_name => user.name, :point_name => point.name)      
  end
end

class ActivityPointRevisionContent < Activity
  def name
    I18n.t('activity.point.revision.content.name', :user_name => user.name, :point_name => point.name)      
  end
end

class ActivityPointRevisionName < Activity
  def name
    I18n.t('activity.point.revision.name', :user_name => user.name, :point_name => point.name)
  end
end

class ActivityPointRevisionOtherPriority < Activity
  def name
    if revision.has_other_priority?
      I18n.t('activity.point.revision.link.new.name', :user_name => user.name, :point_name => point.name, :priority_name => revision.other_priority.name)
    else
      I18n.t('activity.point.revision.link.deleted.name', :user_name => user.name, :point_name => point.name)
    end
  end
end

class ActivityPointRevisionWebsite < Activity
  def name
    if revision.has_website?
      I18n.t('activity.point.revision.website.new.name', :user_name => user.name, :point_name => point.name)
    else
      I18n.t('activity.point.revision.website.deleted.name', :user_name => user.name, :point_name => point.name)
    end
  end
end

class ActivityPointRevisionSupportive < Activity
  def name
    I18n.t('activity.point.revision.supportive.name', :user_name => user.name, :point_name => point.name, :priority_name => priority.name)    
  end
end

class ActivityPointRevisionNeutral < Activity
  def name
    I18n.t('activity.point.revision.neutral.name', :user_name => user.name, :point_name => point.name, :priority_name => priority.name)    
  end
end

class ActivityPointRevisionOpposition < Activity
  def name
    I18n.t('activity.point.revision.opposition.name', :user_name => user.name, :point_name => point.name, :priority_name => priority.name)    
  end
end

class ActivityPointHelpful < Activity
  def name
    I18n.t('activity.point.helpful.name', :user_name => user.name, :point_name => point.name)    
  end
end

class ActivityPointUnhelpful < Activity
  def name
    I18n.t('activity.point.unhelpful.name', :user_name => user.name, :point_name => point.name)    
  end
end

class ActivityPointHelpfulDelete < Activity
  def name
    I18n.t('activity.point.helpful.delete.name', :user_name => user.name, :point_name => point.name)    
  end
end

class ActivityPointUnhelpfulDelete < Activity
  def name
    I18n.t('activity.point.unhelpful.delete.name', :user_name => user.name, :point_name => point.name)    
  end
end

class ActivityUserPictureNew < Activity
  def name
    I18n.t('activity.user.picture.new.name', :user_name => user.name)
  end
end

class ActivityPartnerPictureNew < Activity
  def name
    I18n.t('activity.partner.picture.new.name', :user_name => user.name, :partner_name => partner.name)
  end
end

class ActivityCapitalPointHelpfulEveryone < Activity
  def name
    if capital.amount > 0
      I18n.t('activity.capital.point.helpful.everyone.name', :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)  
    elsif capital.amount < 0
      I18n.t('activity.capital.point.unhelpful.everyone.name', :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)    
    end
  end
end

class ActivityCapitalPointHelpfulEndorsers < Activity
  def name
    if capital.amount > 0
      I18n.t('activity.capital.point.helpful.endorsers.name', :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)  
    elsif capital.amount < 0
      I18n.t('activity.capital.point.unhelpful.endorsers.name', :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)    
    end
  end
end

class ActivityCapitalPointHelpfulOpposers < Activity
  def name
    if capital.amount > 0
      I18n.t('activity.capital.point.helpful.opposers.name', :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)  
    elsif capital.amount < 0
      I18n.t('activity.capital.point.unhelpful.opposers.name', :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)    
    end
  end
end

class ActivityCapitalPointHelpfulUndeclareds < Activity
  def name
    if capital.amount > 0
      I18n.t('activity.capital.point.helpful.undeclareds.name', :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)  
    elsif capital.amount < 0
      I18n.t('activity.capital.point.unhelpful.undeclareds.name', :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)    
    end
  end
end

class ActivityCapitalPointHelpfulDeleted < Activity
  def name
      I18n.t('activity.capital.point.helpful.deleted.name', :user_name => user.name, :point_name => point.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)        
  end
end

# this is currently turned off, but the idea was to give capital for followers on twitter.
class ActivityCapitalTwitterFollowers < Activity
  def name
    if capital.amount > 0
      I18n.t('activity.capital.twitter.followers.earned.name', :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)          
    elsif capital.amount < 0
      I18n.t('activity.capital.twitter.followers.lost.name', :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)         
    end
  end
end

class ActivityCapitalFollowers < Activity
  def name
    if capital.amount > 0
      I18n.t('activity.capital.followers.earned.name', :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)          
    elsif capital.amount < 0
      I18n.t('activity.capital.followers.lost.name', :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)         
    end
  end
end

class ActivityCapitalGovernmentNew < Activity
  def name
    I18n.t('activity.capital.government.new.name', :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)
  end
end

class ActivityFollowingNew < Activity
  def name
    I18n.t('activity.following.new.name', :user_name => user.name, :other_user_name => other_user.name)
  end
end

class ActivityFollowingDelete < Activity
  def name
    I18n.t('activity.following.delete.name', :user_name => user.name, :other_user_name => other_user.name)
  end
end

class ActivityCapitalIgnorers < Activity
  def name
    if capital.amount > 0
      I18n.t('activity.capital.ignorers.earned.name', :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)          
    elsif capital.amount < 0
      I18n.t('activity.capital.ignorers.lost.name', :user_name => user.name, :count => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)         
    end
  end
end

class ActivityCapitalInactive < Activity
  def name
      I18n.t('activity.capital.inactive.name', :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)   
  end
end

class ActivityCapitalLegislatorsAdded < Activity
  def name
      I18n.t('activity.capital.legislators.added.name', :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)   
  end
end

class ActivityIgnoringNew < Activity
  def name
    I18n.t('activity.ignoring.new.name', :user_name => user.name, :other_user_name => other_user.name)
  end
end

class ActivityIgnoringDelete < Activity
  def name
    I18n.t('activity.ignoring.delete.name', :user_name => user.name, :other_user_name => other_user.name)
  end
end

class ActivityObamaLetter < Activity
  def name
    I18n.t('activity.obama_letter.name', :user_name => user.name, :official_user_name => Government.current.official_user.name)
  end
end

class ActivityCapitalObamaLetter < Activity
  def name
      I18n.t('activity.capital.obama_letter.name', :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name, :official_user_name => Government.current.official_user.name)   
  end
end

class ActivityCapitalAdNew < Activity
  def name
      I18n.t('activity.capital.ad.new.name', :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name, :priority_name => priority.name)   
  end
end

class ActivityCapitalAcquisitionProposal < Activity
  def name
      I18n.t('activity.capital.acquisition.proposal.new.name', :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name, :priority_name => priority.name, :new_priority_name => change.new_priority.name)   
  end
end

class ActivityPriorityAcquisitionProposalNo < Activity
  def name
    I18n.t('activity.priority.acquisition.proposal.novote.name', :user_name => user.name, :priority_name => priority.name, :new_priority_name => change.new_priority.name)    
  end
end

class ActivityPriorityAcquisitionProposalApproved < Activity
  def name
    I18n.t('activity.priority.acquisition.proposal.approved.name', :priority_name => priority.name, :new_priority_name => change.new_priority.name)
  end
end

class ActivityPriorityAcquisitionProposalDeclined < Activity
  def name
    I18n.t('activity.priority.acquisition.proposal.declined.name', :priority_name => priority.name, :new_priority_name => change.new_priority.name)
  end
end

class ActivityPriorityAcquisitionProposalDeleted < Activity
  def name
    I18n.t('activity.priority.acquisition.proposal.deleted.name', :user_name => user.name, :priority_name => priority.name, :new_priority_name => change.new_priority.name)  
  end
end

class ActivityCapitalAcquisitionProposalDeleted < Activity
  def name
      I18n.t('activity.capital.acquisition.proposal.deleted.name', :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name, :priority_name => priority.name, :new_priority_name => change.new_priority.name) 
  end
end

class ActivityCapitalAcquisitionProposalApproved < Activity
  def name
      I18n.t('activity.capital.acquisition.proposal.approved.name', :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name, :priority_name => priority.name, :new_priority_name => change.new_priority.name) 
  end
end

class ActivityPriorityObamaStatusFailed < Activity
  def name
    I18n.t('activity.priority.obama_status.failed.name', :priority_name => priority.name)
  end
end

class ActivityPriorityObamaStatusCompromised < Activity
  def name
    I18n.t('activity.priority.obama_status.compromised.name', :priority_name => priority.name)
  end
end

class ActivityPriorityObamaStatusInTheWorks < Activity
  def name
    I18n.t('activity.priority.obama_status.intheworks.name', :priority_name => priority.name)
  end
end

class ActivityPriorityObamaStatusSuccessful < Activity
  def name
    I18n.t('activity.priority.obama_status.successful.name', :priority_name => priority.name)
  end
end

class ActivityDocumentNew < Activity
  
  def name
    I18n.t('activity.point.new.name', :user_name => user.name, :point_name => document.name, :priority_name => priority.name)
  end
  
end

class ActivityDocumentDeleted < Activity
  def name
    I18n.t('activity.point.deleted.name', :user_name => user.name, :point_name => document.name)      
  end
end

class ActivityDocumentRevisionContent < Activity
  def name
    I18n.t('activity.point.revision.content.name', :user_name => user.name, :point_name => document.name)      
  end
end

class ActivityDocumentRevisionName < Activity
  def name
    I18n.t('activity.point.revision.name', :user_name => user.name, :point_name => document.name)
  end
end

class ActivityDocumentRevisionSupportive < Activity
  def name
    I18n.t('activity.point.revision.supportive.name', :user_name => user.name, :point_name => document.name, :priority_name => priority.name)    
  end
end

class ActivityDocumentRevisionNeutral < Activity
  def name
    I18n.t('activity.point.revision.neutral.name', :user_name => user.name, :point_name => document.name, :priority_name => priority.name)    
  end
end

class ActivityDocumentRevisionOpposition < Activity
  def name
    I18n.t('activity.point.revision.opposition.name', :user_name => user.name, :point_name => document.name, :priority_name => priority.name)    
  end
end

class ActivityDocumentHelpful < Activity
  def name
    I18n.t('activity.point.helpful.name', :user_name => user.name, :point_name => document.name)    
  end
end

class ActivityDocumentUnhelpful < Activity
  def name
    I18n.t('activity.point.unhelpful.name', :user_name => user.name, :point_name => document.name)    
  end
end

class ActivityDocumentHelpfulDelete < Activity
  def name
    I18n.t('activity.point.helpful.delete.name', :user_name => user.name, :point_name => document.name)    
  end
end

class ActivityDocumentUnhelpfulDelete < Activity
  def name
    I18n.t('activity.point.unhelpful.delete.name', :user_name => user.name, :point_name => document.name)    
  end
end

class ActivityCapitalDocumentHelpfulEveryone < Activity
  def name
    if capital.amount > 0
      I18n.t('activity.capital.point.helpful.everyone.name', :user_name => user.name, :point_name => document.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)  
    elsif capital.amount < 0
      I18n.t('activity.capital.point.unhelpful.everyone.name', :user_name => user.name, :point_name => document.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)    
    end
  end
end

class ActivityCapitalDocumentHelpfulEndorsers < Activity
  def name
    if capital.amount > 0
      I18n.t('activity.capital.point.helpful.endorsers.name', :user_name => user.name, :point_name => document.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)  
    elsif capital.amount < 0
      I18n.t('activity.capital.point.unhelpful.endorsers.name', :user_name => user.name, :point_name => document.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)    
    end
  end
end

class ActivityCapitalDocumentHelpfulOpposers < Activity
  def name
    if capital.amount > 0
      I18n.t('activity.capital.point.helpful.opposers.name', :user_name => user.name, :point_name => document.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)  
    elsif capital.amount < 0
      I18n.t('activity.capital.point.unhelpful.opposers.name', :user_name => user.name, :point_name => document.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)    
    end
  end
end

class ActivityCapitalDocumentHelpfulUndeclareds < Activity
  def name
    if capital.amount > 0
      I18n.t('activity.capital.point.helpful.undeclareds.name', :user_name => user.name, :point_name => document.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)  
    elsif capital.amount < 0
      I18n.t('activity.capital.point.unhelpful.undeclareds.name', :user_name => user.name, :point_name => document.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)    
    end
  end
end

class ActivityCapitalDocumentHelpfulDeleted < Activity
  def name
      I18n.t('activity.capital.point.helpful.deleted.name', :user_name => user.name, :point_name => document.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)        
  end
end

class ActivityCapitalWarning < Activity
  def name
    I18n.t('activity.capital.warning.name', :user_name => user.name, :capital => capital.amount.abs, :currency_short_name => Government.current.currency_short_name)
  end
end

class ActivityUserProbation < Activity
  def name
    I18n.t('activity.user.probation.name', :user_name => user.name)
  end
end