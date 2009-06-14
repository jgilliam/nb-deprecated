require 'digest/sha1'
class User < ActiveRecord::Base

  extend ActiveSupport::Memoizable
  
  named_scope :active, :conditions => "users.status in ('pending','active')"
  named_scope :at_least_one_endorsement, :conditions => "users.endorsements_count > 0"
  named_scope :newsletter_subscribed, :conditions => "users.is_newsletter_subscribed = 1 and users.email is not null and users.email <> ''"
  named_scope :comments_unsubscribed, :conditions => "users.is_comments_subscribed = 0"  
  named_scope :twitterers, :conditions => "users.twitter_login is not null and users.twitter_login <> ''"
  named_scope :authorized_twitterers, :conditions => "users.twitter_token is not null"
  named_scope :uncrawled_twitterers, :conditions => "users.twitter_crawled_at is null"
  named_scope :contributed, :conditions => "users.document_revisions_count > 0 or users.point_revisions_count > 0"
  named_scope :no_recent_login, :conditions => "users.loggedin_at < date_add(now(), INTERVAL -90 DAY)"
  named_scope :admins, :conditions => "users.is_admin = 1"
  named_scope :suspended, :conditions => "users.status = 'suspended'"
  named_scope :probation, :conditions => "users.status = 'probation'"
  named_scope :deleted, :conditions => "users.status = 'deleted'"
  named_scope :pending, :conditions => "users.status = 'pending'"  
  named_scope :warnings, :conditions => "warnings_count > 0"
  named_scope :no_branch, :conditions => "branch_id is null"
  named_scope :with_branch, :conditions => "branch_id is not null"
  
  named_scope :by_capital, :order => "users.capitals_count desc, users.score desc"
  named_scope :by_ranking, :conditions => "users.position > 0", :order => "users.position asc"  
  named_scope :by_talkative, :conditions => "users.comments_count > 0", :order => "users.comments_count desc"
  named_scope :by_twitter_count, :order => "users.twitter_count desc"
  named_scope :by_recently_created, :order => "users.created_at desc"
  named_scope :by_revisions, :order => "users.document_revisions_count+users.point_revisions_count desc"
  named_scope :by_invites_accepted, :conditions => "users.contacts_invited_count > 0", :order => "users.referrals_count desc"
  named_scope :by_suspended_at, :order => "users.suspended_at desc"
  named_scope :by_deleted_at, :order => "users.deleted_at desc"
  named_scope :by_recently_loggedin, :order => "users.loggedin_at desc"
  named_scope :by_probation_at, :order => "users.probation_at desc"
  named_scope :by_oldest_updated_at, :order => "users.updated_at asc"
  named_scope :by_twitter_crawled_at, :order => "users.twitter_crawled_at asc"
  
  named_scope :by_24hr_gainers, :conditions => "users.endorsements_count > 4", :order => "users.index_24hr_change desc"
  named_scope :by_24hr_losers, :conditions => "users.endorsements_count > 4", :order => "users.index_24hr_change asc"  
  named_scope :by_7days_gainers, :conditions => "users.endorsements_count > 4", :order => "users.index_7days_change desc"
  named_scope :by_7days_losers, :conditions => "users.endorsements_count > 4", :order => "users.index_7days_change asc"  
  named_scope :by_30days_gainers, :conditions => "users.endorsements_count > 4", :order => "users.index_30days_change desc"
  named_scope :by_30days_losers, :conditions => "users.endorsements_count > 4", :order => "users.index_30days_change asc"  

  belongs_to :picture
  belongs_to :partner
  belongs_to :branch
  belongs_to :referral, :class_name => "User", :foreign_key => "referral_id"
  belongs_to :partner_referral, :class_name => "Partner", :foreign_key => "partner_referral_id"
  belongs_to :top_endorsement, :class_name => "Endorsement", :foreign_key => "top_endorsement_id", :include => :priority  

  has_one :profile, :dependent => :destroy

  has_many :unsubscribes, :dependent => :destroy
  has_many :signups
  has_many :partners, :through => :signups
    
  has_many :endorsements, :dependent => :destroy
  has_many :priorities, :conditions => "endorsements.status = 'active'", :through => :endorsements
  has_many :finished_priorities, :conditions => "endorsements.status = 'finished'", :through => :endorsements, :source => :priority
    
  has_many :created_priorities, :class_name => "Priority"
  
  has_many :activities, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :point_revisions, :class_name => "Revision", :dependent => :destroy
  has_many :documents, :dependent => :destroy  
  has_many :document_revisions, :class_name => "DocumentRevision", :dependent => :destroy
  has_many :changes, :dependent => :nullify
  has_many :rankings, :class_name => "UserRanking", :dependent => :destroy
  
  has_many :constituents
  has_many :legislators, :through => :constituents
  
  has_many :point_qualities, :dependent => :destroy
  has_many :document_qualities, :dependent => :destroy
  
  has_many :votes, :dependent => :destroy

  has_many :comments, :dependent => :destroy
  has_many :blasts, :dependent => :destroy
  has_many :ads, :dependent => :destroy
  has_many :shown_ads, :dependent => :destroy
  has_many :charts, :class_name => "UserChart", :dependent => :destroy
  has_many :contacts, :class_name => "UserContact", :dependent => :destroy  

  has_many :sent_messages, :foreign_key => "sender_id", :class_name => "Message"
  has_many :received_messages, :foreign_key => "recipient_id", :class_name => "Message"

  has_many :sent_capitals, :foreign_key => "sender_id", :class_name => "Capital"
  has_many :received_capitals, :foreign_key => "recipient_id", :class_name => "Capital"
  has_many :capitals, :as => :capitalizable, :dependent => :nullify # this is for capitals about them, not capital they've given or received

  has_many :sent_notifications, :foreign_key => "sender_id", :class_name => "Notification"
  has_many :received_notifications, :foreign_key => "recipient_id", :class_name => "Notification"
  has_many :notifications, :as => :notifiable, :dependent => :nullify # this is for notificiations about them, not notifications they've given or received
  
  has_many :followings
  has_many :followers, :foreign_key => "other_user_id", :class_name => "Following"
  
  has_many :following_discussions, :dependent => :destroy
  has_many :following_discussion_activities, :through => :following_discussions, :source => :activity
  
  # oauth stuff
  # http://github.com/pelle/oauth-plugin/tree/master
  has_many :client_applications
  has_many :tokens, :class_name=>"OauthToken", :order=>"authorized_at desc", :include=>[:client_application]
  
  liquid_methods :first_name, :last_name, :id, :name, :login, :activation_code, :email, :root_url, :profile_url, :unsubscribe_url
  
  validates_presence_of     :login, :message => I18n.t('users.new.validation.login')
  validates_length_of       :login, :within => 3..40
  validates_uniqueness_of   :login, :case_sensitive => false    
  
  validates_presence_of     :email, :unless => [:has_facebook?, :has_twitter?]
  validates_length_of       :email, :within => 3..100, :allow_nil => true, :allow_blank => true
  validates_uniqueness_of   :email, :case_sensitive => false, :allow_nil => true, :allow_blank => true
  validates_uniqueness_of   :facebook_uid, :allow_nil => true, :allow_blank => true
  validates_format_of       :email, :with => /^[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+$/x, :allow_nil => true, :allow_blank => true
    
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?

  before_save :encrypt_password
  before_create :make_rss_code
  before_create :check_branch
  after_save :update_signups
  after_create :check_contacts
  after_create :give_partner_credit
  after_create :give_user_credit
  after_create :new_user_signedup
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation, :first_name, :last_name, :twitter_login, :twitter_id, :twitter_token, :twitter_secret, :birth_date, :zip, :website, :is_mergeable, :is_comments_subscribed, :is_votes_subscribed, :is_admin_subscribed, :is_newsletter_subscribed, :is_point_changes_subscribed, :partner_ids, :is_messages_subscribed, :is_followers_subscribed, :is_finished_subscribed, :facebook_uid, :address, :city, :state, :branch_id
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password, :partner_ids  
  
  def new_user_signedup
    ActivityUserNew.create(:user => self, :partner => partner)    
    resend_activation if self.has_email?
  end
  
  def check_branch
    return if has_branch? or not Government.current.is_branches?
    self.branch = Government.current.default_branch
    Government.current.default_branch.increment!(:users_count) 
    Branch.expire_cache
  end
  
  def check_contacts
    if self.has_email?
      existing_contacts = UserContact.find(:all, :conditions => ["email = ? and other_user_id is null",email], :order => "created_at asc")
      for c in existing_contacts
        if c.is_invited? # they were invited by this person
          c.accept!
        else # they're in the contacts, but not invited by this person
           c.update_attribute(:other_user_id,self.id)
           notifications << NotificationContactJoined.new(:sender => self, :recipient => c.user)
           c.user.increment!(:contacts_members_count)
           c.user.decrement!(:contacts_not_invited_count)         
        end
      end
    end
    if self.has_facebook?
      existing_contacts = UserContact.find(:all, :conditions => ["facebook_uid = ? and other_user_id is null",self.facebook_uid], :order => "created_at asc")
      for c in existing_contacts
        if c.is_invited? # they were invited by this person
          c.accept!
        else
          c.update_attribute(:other_user_id,self.id)
        end
      end    
    end
  end
  
  def give_partner_credit
    return unless partner_referral
    ActivityPartnerUserRecruited.create(:user => partner_referral.owner, :other_user => self, :partner => partner_referral)
    ActivityCapitalPartnerUserRecruited.create(:user => partner_referral.owner, :other_user => self, :partner => partner_referral, :capital => CapitalPartnerUserRecruited.create(:recipient => partner_referral.owner, :amount => 2, :capitalizable => self))
    partner_referral.owner.increment!(:referrals_count)
  end
  
  def give_user_credit
    return unless referral
    ActivityInvitationAccepted.create(:other_user => referral, :user => self)
    ActivityUserRecruited.create(:user => referral, :other_user => self, :is_user_only => true) 
    referral.increment!(:referrals_count)
  end  
  
  def update_signups
    unless partner_ids.nil?
      self.signups.each do |s|
        s.destroy unless partner_ids.include?(s.partner_id.to_s)
        partner_ids.delete(s.partner_id.to_s)
      end 
      partner_ids.each do |p|
        self.signups.create(:partner_id => p) unless p.blank?
      end
      reload
      self.partner_ids = nil
    end
  end
  
  # docs: http://www.vaporbase.com/postings/stateful_authentication
  acts_as_state_machine :initial => :pending, :column => :status

  state :passive
  state :pending, :enter => :do_pending
  state :active, :enter => :do_activate
  state :suspended, :enter => :do_suspension
  state :probation, :enter => :do_probation
  state :deleted, :enter => :do_delete  

  event :register do
    transitions :from => :passive, :to => :pending, :guard => Proc.new {|u| !(u.crypted_password.blank? && u.password.blank?) }
  end

  event :activate do
    transitions :from => [:pending, :passive], :to => :active 
  end
  
  event :suspend do
    transitions :from => [:passive, :pending, :active, :probation], :to => :suspended
  end
  
  event :delete do
    transitions :from => [:passive, :pending, :active, :suspended, :probation], :to => :deleted
  end

  event :unsuspend do
    transitions :from => :suspended, :to => :active, :guard => Proc.new {|u| !u.activated_at.blank? }
    transitions :from => :suspended, :to => :pending, :guard => Proc.new {|u| !u.activation_code.blank? }
    transitions :from => :suspended, :to => :passive
  end
  
  event :probation do
    transitions :from => [:passive, :pending, :active], :to => :probation    
  end
  
  event :unprobation do
    transitions :from => :probation, :to => :active, :guard => Proc.new {|u| !u.activated_at.blank? }
    transitions :from => :probation, :to => :pending, :guard => Proc.new {|u| !u.activation_code.blank? }
    transitions :from => :probation, :to => :passive    
  end

  def do_pending
    self.probation_at = nil
    self.suspended_at = nil
    self.deleted_at = nil    
  end

  # Activates the user in the database.
  def do_activate
    @activated = true
    self.activated_at ||= Time.now.utc
    self.activation_code = nil
    self.probation_at = nil
    self.suspended_at = nil
    self.deleted_at = nil
    for e in endorsements.suspended
      e.unsuspend!
    end    
  end  
  
  def do_delete
    self.deleted_at = Time.now
    for e in endorsements
      e.destroy
    end    
    for f in followings
      f.destroy
    end
    for f in followers
      f.destroy
    end 
    for c in received_capitals
      c.destroy
    end
    for c in sent_capitals
      c.destroy
    end
    for c in constituents
      c.destroy
    end
    self.facebook_uid = nil
  end
  
  def do_probation
    self.probation_at = Time.now
    ActivityUserProbation.create(:user => self)
  end
  
  def do_suspension
    self.suspended_at = Time.now
    for e in endorsements.active
      e.suspend!
    end
  end  
  
  def resend_activation
    make_activation_code
    UserMailer.deliver_welcome(self)    
  end
  
  def to_param
    "#{id}-#{login.gsub(/[^a-z0-9]+/i, '-').downcase}"
  end  
  
  cattr_reader :per_page
  @@per_page = 25  
  
  def request=(request)
    self.ip_address = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.referrer = request.env['HTTP_REFERER']
  end  
  
  def is_subscribed=(value)
    if not value
      self.is_newsletter_subscribed = false
      self.is_comments_subscribed = false
      self.is_votes_subscribed = false
      self.is_point_changes_subscribed = false      
      self.is_followers_subscribed = false
      self.is_finished_subscribed = false      
      self.is_messages_subscribed = false
      self.is_votes_subscribed = false
      self.is_admin_subscribed = false
    else
      self.is_newsletter_subscribed = true
      self.is_comments_subscribed = true
      self.is_votes_subscribed = true     
      self.is_point_changes_subscribed = true
      self.is_followers_subscribed = true 
      self.is_finished_subscribed = true           
      self.is_messages_subscribed = true
      self.is_votes_subscribed = true
      self.is_admin_subscribed = true
    end
  end
  
  def to_param_link
    '<a href="http://' + Government.current.base_url + '/users/' + sender.to_param + '">' + sender.name + '</a>'  
  end
  
  def has_top_priority?
    attribute_present?("top_endorsement_id")
  end

  def most_recent_activity
    activities.active.by_recently_created.find(:all, :limit => 1)[0]
  end  
  memoize :most_recent_activity

  def priority_list
    s = "My top priorities for America:"
    row = 0
    for e in endorsements
      row=row+1
      s += "\r\n" + row.to_s + ". " + e.priority.name if row < 11
    end
    return s
  end
  memoize :priority_list
    
  # ranking metrics
  def up_issue_diversity
    return 0 if up_endorsements_count < 5 or not Government.current.is_tags?
    up_issues_count.to_f/up_endorsements_count.to_f
  end

  def recent_login?
    return false if loggedin_at.nil?
    loggedin_at > Time.now-30.days
  end

  def calculate_score
    count = 0.1
    count += 1 if active? 
    count += 3 if recent_login?
    count += 0.5 if points_count > 0
    count += up_issue_diversity
    count += 0.6 if constituents_count > 1
    count = count/6
    count = 1 if count > 1
    count = 0.1 if count < 0.1
    return count
  end
  
  def activity_rank
    (score*10).to_i
  end 
  
  def quality_factor
    return 1 if qualities_count < 10
    rev_count = document_revisions_count+point_revisions_count
    return 10/qualities_count.to_f if rev_count == 0
    i = (rev_count*2).to_f/qualities_count.to_f
    return 1 if i > 1
    return i
  end
  memoize :quality_factor
  
  def address_full
    a = ""
    a += address + ", " if attribute_present?("address")
    a += city + ", " if attribute_present?("city")
    a += state + ", " if attribute_present?("state")
    a += zip if attribute_present?("zip")
    a
  end
  
  def attach_legislators
    return 0 unless attribute_present?("zip")
    constituents.destroy_all
    if attribute_present?("address")
      begin
        sun = Sunlight::Legislator.all_for(:address => address_full)
        if sun and sun.size > 0
          constituents << Constituent.new(:legislator => Legislator.find_by_govtrack_id(sun[:senior_senator].govtrack_id)) if sun[:senior_senator]
          constituents << Constituent.new(:legislator => Legislator.find_by_govtrack_id(sun[:junior_senator].govtrack_id)) if sun[:junior_senator]
          constituents << Constituent.new(:legislator => Legislator.find_by_govtrack_id(sun[:representative].govtrack_id)) if sun[:representative]
        end    
      rescue
      end  
    elsif zip.length == 10 and zip[4] == '-'
      begin
        sun = Sunlight::Legislator.all_for(:address => zip)
        if sun and sun.size > 0
          constituents << Constituent.new(:legislator => Legislator.find_by_govtrack_id(sun[:senior_senator].govtrack_id)) if sun[:senior_senator]
          constituents << Constituent.new(:legislator => Legislator.find_by_govtrack_id(sun[:junior_senator].govtrack_id)) if sun[:junior_senator]
          constituents << Constituent.new(:legislator => Legislator.find_by_govtrack_id(sun[:representative].govtrack_id)) if sun[:representative]
        end
      rescue
      end
    end
    if constituents.empty? and zip.to_i > 0
      begin
        sun = Sunlight::Legislator.all_in_zipcode(zip[0..4])
        if sun and sun.size > 3 # only pull in their senators, need more info to pick their rep
          for s in sun
            if s.title == 'Sen'
              constituents << Constituent.new(:legislator => Legislator.find_by_govtrack_id(s.govtrack_id))
            end
          end            
        elsif sun and sun.size < 4
          for s in sun
            constituents << Constituent.new(:legislator => Legislator.find_by_govtrack_id(s.govtrack_id))
          end
        end
      rescue
        return 0
      end
    end
    return constituents.size
  end
  
  def revisions_count
    document_revisions_count+point_revisions_count-points_count-documents_count 
  end
  memoize :revisions_count
  
  def pick_ad(current_priority_ids)
  	shown = 0
  	for ad in Ad.active.most_paid.all
  		if shown == 0 and not current_priority_ids.include?(ad.priority_id)
  			shown_ad = ad.shown_ads.find_by_user_id(self.id)
  			if shown_ad and not shown_ad.has_response? and shown_ad.seen_count < 4
  				shown_ad.increment!(:seen_count)
  				return ad
  			elsif not shown_ad
  				shown_ad = ad.shown_ads.create(:user => self)
  				return ad
  			end
  		end
  	end    
  	return nil
  end
  
  def following_user_ids
    followings.collect{|f|f.other_user_id}
  end
  memoize :following_user_ids
  
  def follower_user_ids
    followers.collect{|f|f.user_id}
  end
  memoize :follower_user_ids
  
  def load_google_contacts
    offset = 0
    Rails.cache.write(["#{Government.current.short_name}-contacts_number",self.id], offset)  
    gmail = Contacts::Google.new(self.email, self.google_token)
    gcontacts = gmail.all_contacts
    for c in gcontacts
      begin
        contact = contacts.find_by_email(c.email)
        contact = contacts.new unless contact
        contact.name = c.name
        contact.email = c.email
        contact.other_user = User.find_by_email(contact.email)
        if self.followings_count > 0 and contact.other_user
          contact.following = followings.find_by_other_user_id(contact.other_user_id)
        end
        contact.save_with_validation(false)          
        offset += 1
        Rails.cache.write(["#{Government.current.short_name}-contacts_number",self.id], offset)
      rescue
        next
      end
    end
    Rails.cache.write(["#{Government.current.short_name}-contacts_finished",self.id], true)
  end
  
  def load_yahoo_contacts(path)
    offset = 0
    Rails.cache.write(["#{Government.current.short_name}-contacts_number",self.id], offset)  
    yahoo = Contacts::Yahoo.new
    ycontacts = yahoo.contacts(path)
    if ycontacts.empty?
      break 
    end
    for c in ycontacts
      begin
        if c.email
          contact = contacts.find_by_email(c.email)
          contact = contacts.new unless contact
          contact.name = c.name
          contact.email = c.email
          contact.other_user = User.find_by_email(contact.email)
          if self.followings_count > 0 and contact.other_user
            contact.following = followings.find_by_other_user_id(contact.other_user_id)
          end
          contact.save_with_validation(false)          
          offset += 1
        end
        Rails.cache.write(["#{Government.current.short_name}-contacts_number",self.id], offset)
      rescue
        next
      end
    end
    Rails.cache.write(["#{Government.current.short_name}-contacts_finished",self.id], true)
  end  
  
  def load_windows_contacts(path)
    offset = 0
    Rails.cache.write(["#{Government.current.short_name}-contacts_number",self.id], offset)  
    wl = Contacts::WindowsLive.new
    wcontacts = wl.contacts(path)
    if wcontacts.empty?
      break 
    end
    for c in wcontacts
      begin
        if c.email
          contact = contacts.find_by_email(c.email)
          contact = contacts.new unless contact
          contact.name = c.name
          contact.email = c.email
          contact.other_user = User.find_by_email(contact.email)
          if self.followings_count > 0 and contact.other_user
            contact.following = followings.find_by_other_user_id(contact.other_user_id)
          end
          contact.save_with_validation(false)          
          offset += 1
        end
      rescue
        next
        Rails.cache.write(["#{Government.current.short_name}-contacts_number",self.id], offset)
      end
    end
    Rails.cache.write(["#{Government.current.short_name}-contacts_finished",self.id], true)
  end  
  
  def calculate_contacts_count
    self.contacts_members_count = contacts.active.members.not_following.size
    self.contacts_invited_count = contacts.active.not_members.invited.size
    self.contacts_not_invited_count = contacts.active.not_members.not_invited.size
    self.contacts_count = contacts.active.size
  end

  def expire_charts
    Rails.cache.delete("views/" + Government.current.short_name + "-user_priority_chart_official-#{self.id.to_s}-#{self.endorsements_count.to_s}")
    Rails.cache.delete("views/" + Government.current.short_name + "-user_priority_chart-#{self.id.to_s}-#{self.endorsements_count.to_s}")
  end
  
  def issues(limit=10)
    Tag.find_by_sql(["SELECT tags.*, count(*) as number
    FROM endorsements INNER JOIN taggings ON endorsements.priority_id = taggings.taggable_id
    	 INNER JOIN tags ON taggings.tag_id = tags.id
    where taggings.taggable_type = 'Priority'
    and endorsements.user_id = ?
    and endorsements.status = 'active'
    group by tags.id
    order by number desc
    limit ?",id,limit])
  end
  memoize :issues
  
  def recommend(limit=10)
    return [] unless self.endorsements_count > 0
    sql = "select relationships.percentage, priorities.*
    from relationships,priorities
    where relationships.other_priority_id = priorities.id and ("
    if up_endorsements_count > 0
      sql += "(relationships.priority_id in (#{endorsements.active_and_inactive.endorsing.collect{|e|e.priority_id}.join(',')}) and relationships.type = 'RelationshipEndorserEndorsed')"
    end
    if up_endorsements_count > 0 and down_endorsements_count > 0
      sql += " or "
    end
    if down_endorsements_count > 0
      sql += "(relationships.priority_id in (#{endorsements.active_and_inactive.opposing.collect{|e|e.priority_id}.join(',')}) and relationships.type = 'RelationshipOpposerEndorsed')"
    end
    sql += ") and relationships.other_priority_id not in (select priority_id from endorsements where user_id = " + self.id.to_s + ")
    and priorities.position > 25
    and priorities.status = 'published'
    group by relationships.other_priority_id
    order by relationships.percentage desc"
    sql += " limit " + limit.to_s
    
    Priority.find_by_sql(sql).paginate :per_page => limit, :page => 1
  end
  memoize :recommend

  # this needs to be smarter.  it should take into account how much stuff you don't agree on too
  def allies(limit=10)
    fid = followings.collect{|f|f.other_user_id }
    fid << id
    User.find_by_sql(["select users.*, count(e2.value)*(?-users.endorsements_count)/? as number
    from endorsements e1, endorsements e2, users
    where e1.priority_id = e2.priority_id
    and e1.value = e2.value
    and e1.status = 'active' and e2.status = 'active'
    and e2.user_id = users.id
    and e1.user_id = ? and e2.user_id not in (?)
    and users.score > .4
    group by e2.user_id
    order by number desc limit ?",endorsements_count,endorsements_count,id,fid,limit])
  end
  memoize :allies
  
  def opponents(limit=10)
    User.find_by_sql(["select users.*, count(value)*(?-users.endorsements_count)/? as number
    from endorsements e1, endorsements e2, users
    where e1.priority_id = e2.priority_id
    and e1.value <> e2.value
    and e1.status = 'active' and e2.status = 'active'
    and e2.user_id = users.id
    and e1.user_id = ? and e2.user_id <> ?
    and users.score > .4
    group by e2.user_id
    order by number desc limit ?",endorsements_count,endorsements_count,id,id,limit])
  end  
  memoize :opponents
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(email, password)
    u = find :first, :conditions => ["email = ? and status in ('active','pending')", email] # need to get the salt
    if u && u.authenticated?(password) 
      #u.update_attribute(:loggedin_at,Time.now)
      return u
    else
      return nil
    end
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 4.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save_with_validation(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save_with_validation(false)
  end

  def name
    return login
  end
  
  def real_name
    return login if not attribute_present?("first_name") or not attribute_present?("last_name")
    n = first_name + ' ' + last_name
    n
  end
  
  def is_partner?
    attribute_present?("partner_id")
  end
  
  def is_new?
    created_at > Time.now-(86400*7)
  end
  
  def is_influential?
    return false if position == 0
    position < Endorsement.max_position 
  end
  
  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  def activated?
    active?
  end
  
  def is_active?
    ['pending','active'].include?(status)
  end

  def is_suspended?
    ['suspended'].include?(status)
  end

  def is_pending?
    status == 'pending'
  end  
  
  def is_ambassador?
    contacts_invited_count > 0    
  end
  
  def has_picture?
    attribute_present?("picture_id")
  end
  
  def has_referral?
    attribute_present?("referral_id")
  end
  
  def has_partner_referral?
    attribute_present?("partner_referral_id") and partner_referral_id != 1
  end  
  
  def has_twitter?
    attribute_present?("twitter_token")
  end

  def has_website?
    attribute_present?("website")
  end
  
  def has_zip?
    attribute_present?("zip")
  end  
  
  def website_link
    return nil if self.website.nil?
    wu = website
    wu = 'http://' + wu if wu[0..3] != 'http'
    return wu    
  end  

  def capital_received
    Capital.sum(:amount, :conditions => ["recipient_id = ?",id])    
  end

  def capital_spent
    Capital.sum(:amount, :conditions => ["sender_id = ?",id])
  end
  
  def inactivity_capital_lost
    Capital.sum(:amount, :conditions => ["recipient_id = ? and type='CapitalInactive'",id]) 
  end
  
  def has_capital?
    capitals_count != 0
  end

  def has_google_token?
    attribute_present?("google_token")
  end
  
  def update_capital
    self.update_attribute(:capitals_count,capital_received-capital_spent)
  end  
  
  def follow(u)
    return nil if u.id == self.id
    f = followings.find_by_other_user_id(u.id)
    return f if f and f.value == 1
    unignore(u) if f and f.value == -1
    following = followings.create(:other_user => u, :value => 1)
    contact_exists = contacts.find_by_other_user_id(u.id)
    if contact_exists
      contact_exists.update_attribute(:following_id, following.id)
      self.decrement!(:contacts_members_count)        
    end
    return following
  end
  
  def unfollow(u)
    f = followings.find_by_other_user_id_and_value(u.id,1)
    f.destroy if f
    contact_exists = contacts.find_by_other_user_id(u.id)
    if contact_exists
      contact_exists.update_attribute(:following_id, nil)
      self.increment!(:contacts_members_count)        
    end     
  end
  
  def ignore(u)
    f = followings.find_by_other_user_id(u.id)
    return f if f and f.value == -1
    unfollow(u) if f and f.value == 1
    followings.create(:other_user => u, :value => -1)    
  end
  
  def unignore(u)
    f = followings.find_by_other_user_id_and_value(u.id,-1)
    f.destroy if f
  end
  
  def reset_password
    new_password = random_password
    self.update_attribute(:password, new_password)
    UserMailer.deliver_new_password(self, new_password)
  end
  
  def random_password( size = 4 )
    c = %w(b c d f g h j k l m n p qu r s t v w x z ch cr fr nd ng nk nt ph pr rd sh sl sp st th tr lt)
    v = %w(a e i o u y)
    f, r = true, ''
    (4 * 2).times do
      r << (f ? c[rand * c.size] : v[rand * v.size])
      f = !f
    end
    r    
  end
  
  def index_charts(limit=30)
    PriorityChart.find_by_sql(["select priority_charts.date_year,priority_charts.date_month,priority_charts.date_day, 
    sum(priority_charts.volume_count) as volume_count,
    sum((priority_charts.down_count*(endorsements.value*-1))+(priority_charts.up_count*endorsements.value)) as down_count, 
    avg(endorsements.value*priority_charts.change_percent) as percentage
    from priority_charts, endorsements
    where endorsements.user_id = ? and endorsements.status = 'active'
    and endorsements.priority_id = priority_charts.priority_id
    group by endorsements.user_id, priority_charts.date_year, priority_charts.date_month, priority_charts.date_day
    order by priority_charts.date_year desc, priority_charts.date_month desc, priority_charts.date_day desc limit ?",id,limit])
  end
  memoize :index_charts
  
  # computes the change in percentage of all their priorities over the last [limit] days.
  def index_change_percent(limit=7)
    index_charts(limit-1).collect{|c|c.percentage.to_f}.reverse.sum
  end
  
  def index_chart_hash(limit=30)
    h = Hash.new
    h[:charts] = index_charts(limit)
    h[:volume_counts] = h[:charts].collect{|c| c.volume_count.to_i}.reverse
    h[:max_volume] = h[:volume_counts].max
    h[:percentages] = h[:charts].collect{|c|c.percentage.to_f}.reverse
    h[:percentages][0] = 0
    for i in 1..h[:percentages].length-1
    	 h[:percentages][i] =  h[:percentages][i-1] + h[:percentages][i]
    end
    h[:max_percentage] = h[:percentages].max.abs
    if h[:max_percentage] < h[:percentages].min.abs
      h[:max_percentage] = h[:percentages].min.abs
    end
    h[:adjusted_percentages] = []
    for i in 0..h[:percentages].length-1
      h[:adjusted_percentages][i] = h[:percentages][i] + h[:max_percentage]
    end
    return h
  end
  
  def index_chart_with_obama_hash(limit=30)
    h = Hash.new
    h[:charts] = index_charts(limit)
    h[:obama_charts] = Government.current.official_user.index_charts(limit)
    h[:percentages] = h[:charts].collect{|c|c.percentage.to_f}.reverse
    h[:percentages][0] = 0
    for i in 1..h[:percentages].length-1
    	 h[:percentages][i] =  h[:percentages][i-1] + h[:percentages][i]
    end
    h[:obama_percentages] = h[:obama_charts].collect{|c|c.percentage.to_f}.reverse
    h[:obama_percentages][0] = 0
    for i in 1..h[:obama_percentages].length-1
    	 h[:obama_percentages][i] = h[:obama_percentages][i-1] + h[:obama_percentages][i]
    end
    
    h[:max_percentage] = h[:percentages].max.abs
    if h[:max_percentage] < h[:percentages].min.abs
      h[:max_percentage] = h[:percentages].min.abs
    end
    if h[:max_percentage] < h[:obama_percentages].max.abs
      h[:max_percentage] = h[:obama_percentages].max.abs
    end
    if h[:max_percentage] < h[:obama_percentages].min.abs
      h[:max_percentage] = h[:obama_percentages].min.abs
    end
        
    h[:adjusted_percentages] = []
    for i in 0..h[:percentages].length-1
      h[:adjusted_percentages][i] = h[:percentages][i] + h[:max_percentage]
    end
    h[:obama_adjusted_percentages] = []
    for i in 0..h[:obama_percentages].length-1
      h[:obama_adjusted_percentages][i] = h[:obama_percentages][i] + h[:max_percentage]
    end    
    return h
  end  
  
  def User.signup_growth
    data = []
    labels = []
    numbers = User.find_by_sql("SELECT DATE_FORMAT(created_at, '%Y-%m-%d') as day, count(*) as 'users_number' FROM users where created_at > '2008-11-01' GROUP BY DATE_FORMAT(created_at, '%Y-%m-%d')")
    t = 0
    numbers.each do |n|
      labels << n.day
      data << t+=n.users_number.to_i
    end
    {:labels => labels, :data => data}
  end
  
  def has_facebook?
    self.attribute_present?("facebook_uid")
  end
  
  def has_email?
    self.attribute_present?("email")
  end  
  
  def has_branch?
    self.attribute_present?("branch_id")
  end
  
  def create_first_and_last_name_from_name(s)
    names = s.split
    self.last_name = names.pop
    self.first_name = names.join(' ')
  end

  def twitter_client
    require 'Grackle'
    Grackle::Client.new(:auth=>{
      :type=>:oauth,
      :consumer_key=> ENV['TWITTER_KEY'], :consumer_secret=>ENV['TWITTER_SECRET_KEY'],
      :token=>self.twitter_token, :token_secret=>self.twitter_secret
    })
  end

  def twitter_followers_count
    require 'Grackle'
    if attribute_present?("twitter_token") # use oauth if they've authorized us
      twitter_client.users.show?(:id => twitter_id).followers_count.to_i      
    elsif DB_CONFIG[RAILS_ENV]['twitter_login'] # or use the overall twitter account if it's in database.yml
      twitter = Grackle::Client.new(:auth=>{:type => :basic, :username => DB_CONFIG[RAILS_ENV]['twitter_login'], :password => DB_CONFIG[RAILS_ENV]['twitter_password']})
      twitter.users.show?(:screen_name => twitter_login).followers_count.to_i
    else
      return 0
    end
  end  
  
  # this can be run on a regular basis
  # it will look up all the people this person is following on twitter, and follow them here
  def follow_twitter_friends
    count = 0
    friend_ids = twitter_client.friends.ids?
    if friend_ids.any?
      if following_user_ids.any?
        users = User.active.find(:all, :conditions => ["twitter_id in (?) and id not in (?)",friend_ids, following_user_ids])
      else
        users = User.active.find(:all, :conditions => ["twitter_id in (?)",friend_ids])
      end
      for user in users
        count += 1
        follow(user)
      end
    end
    return count
  end  
  
  # this is for when someone adds twitter to their account for the first time
  # it will look up all the people who are following this person on twitter and are already members
  # and automatically follow this new person here.
  def twitter_followers_follow
    count = 0
    follower_ids = twitter_client.followers.ids?
    if follower_ids.any?
      if follower_user_ids.any?
        users = User.active.find(:all, :conditions => ["twitter_id in (?) and id not in (?)",follower_ids, follower_user_ids])
      else
        users = User.active.find(:all, :conditions => ["twitter_id in (?)",follower_ids])
      end
      for user in users
        count += 1
        user.follow(self)
      end
    end
    return count    
  end

  def User.create_from_twitter(twitter_info, token, secret, request)
    name = twitter_info['name']
    if User.find_by_login(name)
      name = twitter_info['screen_name']
      if User.find_by_login(name)
        name = name + " TW"
      end
    end
    u = User.new(:twitter_id => twitter_info['id'].to_i, :twitter_token => token, :twitter_secret => secret)
    u.login = name
    u.create_first_and_last_name_from_name(twitter_info['name'])
    u.twitter_login = twitter_info['screen_name']
    u.twitter_count = twitter_info['followers_count'].to_i
    u.website = twitter_info['url']
    u.request = request
    if twitter_info['profile_image_url']
      u.picture = Picture.create_from_url(twitter_info['profile_image_url'])
    end
    if u.save_with_validation(false)
      u.activate!
      return u
    else
      return nil
    end
  end
  
  def update_with_twitter(twitter_info, token, secret, request)
    self.twitter_id = twitter_info['id'].to_i
    self.twitter_login = twitter_info['screen_name']
    self.twitter_token = token
    self.twitter_secret = secret            
    self.website = twitter_info['url'] if not self.has_website?
    if twitter_info['profile_image_url'] and not self.has_picture?
      self.picture = Picture.create_from_url(twitter_info['profile_image_url'])
    end
    self.twitter_count = twitter_info['followers_count'].to_i
    self.save_with_validation(false)
    self.activate! if not self.activated?
  end  
  
  def User.create_from_facebook(fb_session,partner,request)
    return if fb_session.expired?
    name = fb_session.user.name
    # check for existing account with this name
    if User.find_by_login(name)
     name = name + " FB"
    end
    u = User.new(
     :login => name,
     :first_name => fb_session.user.first_name,
     :last_name => fb_session.user.last_name,       
     :facebook_uid => fb_session.user.uid,
     :partner_referral => partner,
     :request => request
    )
    
    if fb_session.user.current_location
      u.zip = fb_session.user.current_location.zip if fb_session.user.current_location.zip and fb_session.user.current_location.zip.any?  
      u.city = fb_session.user.current_location.city if fb_session.user.current_location.city and fb_session.user.current_location.city.any?
      u.state = fb_session.user.current_location.state if fb_session.user.current_location.state and fb_session.user.current_location.state.any?
    end
    if u.save
      u.activate!
      return u
    else
      puts "ERROR w/ user -- " + u.errors.full_messages.join(" | ")
      return nil
    end
  end
  
  def update_with_facebook(fb_session)
    return if fb_session.expired?
    self.facebook_uid = fb_session.user.uid
    # need to do some checking on whether this facebook_uid is already attached to a diff account
    check_existing_facebook = User.active.find(:all, :conditions => ["facebook_uid = ? and id <> ?",self.facebook_uid,self.id])
    if check_existing_facebook.any?
      for e in check_existing_facebook
        e.remove_facebook
        e.save_with_validation(false)
      end
    end
    if fb_session.user.current_location
      self.zip = fb_session.user.current_location.zip if fb_session.user.current_location.zip and fb_session.user.current_location.zip.any? and not self.attribute_present?("zip")
      self.city = fb_session.user.current_location.city if fb_session.user.current_location.city and fb_session.user.current_location.city.any? and not self.attribute_present?("city")
      self.state = fb_session.user.current_location.state if fb_session.user.current_location.state and fb_session.user.current_location.state.any? and not self.attribute_present?("state")
    end
    self.save_with_validation(false)
    check_contacts # looks for any contacts with the facebook uid, and connects them
    return true
  end
  
  def remove_facebook
    return unless has_facebook?
    self.facebook_uid = nil
    # i don't think this does everything necessary to zap facebook from their account
  end  
  
  def make_rss_code
    return self.rss_code if self.attribute_present?("rss_code")
    self.rss_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end  
  
  def root_url
    if has_partner_referral?
      return 'http://' + partner_referral.short_name + '.' + Government.current.base_url + '/'
    else
      return 'http://' + Government.current.base_url + '/'
    end
  end
  
  def profile_url
    'http://' + Government.current.base_url + '/users/' + to_param
  end
  
  def unsubscribe_url
    'http://' + Government.current.base_url + '/unsubscribes/new'
  end
  
  protected
  
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
      
    def password_required?
      !password.blank?
    end
    
    def make_activation_code
      self.update_attribute(:activation_code,Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join ))
    end
    
end
