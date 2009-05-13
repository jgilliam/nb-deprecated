class Priority < ActiveRecord::Base
  
  extend ActiveSupport::Memoizable

  named_scope :published, :conditions => "priorities.status = 'published' and priorities.position > 0 and endorsements_count > 0"

  named_scope :top_rank, :order => "priorities.position asc"
  named_scope :not_top_rank, :conditions => "priorities.position > 25"
  named_scope :rising, :conditions => "priorities.position_7days_change > 0", :order => "(priorities.position_7days_change/priorities.position) desc"
  named_scope :falling, :conditions => "priorities.position_7days_change < 0", :order => "(priorities.position_7days_change/priorities.position) asc"

  named_scope :rising_7days, :conditions => "priorities.position_7days_change > 0"
  named_scope :flat_7days, :conditions => "priorities.position_7days_change = 0"
  named_scope :falling_7days, :conditions => "priorities.position_7days_change < 0"
  named_scope :rising_30days, :conditions => "priorities.position_30days_change > 0"
  named_scope :flat_30days, :conditions => "priorities.position_30days_change = 0"
  named_scope :falling_30days, :conditions => "priorities.position_30days_change < 0"
  named_scope :rising_24hr, :conditions => "priorities.position_24hr_change > 0"
  named_scope :flat_24hr, :conditions => "priorities.position_24hr_change = 0"
  named_scope :falling_24hr, :conditions => "priorities.position_24hr_change < 0"
  
  named_scope :finished, :conditions => "priorities.obama_status in (-2,-1,2)"
  named_scope :random, :order => "rand()"
  
  named_scope :obama_endorsed, :conditions => "priorities.obama_value > 0"
  named_scope :not_obama, :conditions => "priorities.obama_value = 0"
  named_scope :obama_opposed, :conditions => "priorities.obama_value < 0"
  named_scope :not_obama_or_opposed, :conditions => "priorities.obama_value < 1"   
  
  named_scope :alphabetical, :order => "priorities.name asc"
  named_scope :newest, :order => "priorities.published_at desc, priorities.created_at desc"
  named_scope :controversial, :conditions => "(priorities.up_endorsements_count/priorities.down_endorsements_count) between 0.5 and 2", :order => "(priorities.endorsements_count - abs(priorities.up_endorsements_count-priorities.down_endorsements_count)) desc"
  named_scope :tagged, :conditions => "(priorities.cached_issue_list is not null and priorities.cached_issue_list <> '')"
  named_scope :untagged, :conditions => "(priorities.cached_issue_list is null or priorities.cached_issue_list = '')", :order => "priorities.endorsements_count desc, priorities.created_at desc"
  
  named_scope :by_most_recent_status_change, :order => "priorities.status_changed_at desc"
  
  belongs_to :user
  
  has_many :relationships, :dependent => :destroy
  has_many :incoming_relationships, :foreign_key => :other_priority_id, :class_name => "Relationship", :dependent => :destroy
  
  has_many :endorsements, :dependent => :destroy
  has_many :endorsers, :through => :endorsements, :conditions => "endorsements.status in ('active','inactive')", :source => :user, :class_name => "User"
  has_many :up_endorsers, :through => :endorsements, :conditions => "endorsements.status in ('active','inactive') and endorsements.value=1", :source => :user, :class_name => "User"
  has_many :down_endorsers, :through => :endorsements, :conditions => "endorsements.status in ('active','inactive') and endorsements.value=-1", :source => :user, :class_name => "User"
  
  has_many :points, :conditions => "points.status in ('published','draft')"
  has_many :incoming_points, :foreign_key => "other_priority_id", :class_name => "Point"
  has_many :published_points, :conditions => "status = 'published'", :class_name => "Point", :order => "points.helpful_count-points.unhelpful_count desc"
  has_many :points_with_deleted, :class_name => "Point", :dependent => :destroy
  has_many :documents, :dependent => :destroy
  
  has_many :rankings, :dependent => :destroy
  has_many :activities, :dependent => :destroy

  has_many :charts, :class_name => "PriorityChart", :dependent => :destroy
  has_many :ads, :dependent => :destroy
  has_many :notifications, :as => :notifiable, :dependent => :destroy
  
  has_many :changes, :conditions => "status <> 'deleted'", :order => "updated_at desc"
  has_many :approved_changes, :class_name => "Change", :conditions => "status = 'approved'", :order => "updated_at desc"
  has_many :sent_changes, :class_name => "Change", :conditions => "status = 'sent'", :order => "updated_at desc"
  has_many :declined_changes, :class_name => "Change", :conditions => "status = 'declined'", :order => "updated_at desc"
  has_many :changes_with_deleted, :class_name => "Change", :order => "updated_at desc", :dependent => :destroy

  belongs_to :change # if there is currently a pending change, it will be attached
  
  acts_as_taggable_on :issues
  
  # docs: http://noobonrails.blogspot.com/2007/02/actsaslist-makes-lists-drop-dead-easy.html
  acts_as_list
  
  define_index do
    set_property :field_weights => {:name => 10, :issues => 3, :point_name => 3, :point_content => 1}
    indexes :name
    indexes :cached_issue_list, :as => :issues
    indexes :sphinx_index
    indexes points.name, :as => :point_name
    indexes points.content, :as => :point_content
    where "priorities.status in ('published','inactive')"
  end
  
  liquid_methods :id, :name, :show_url, :value_name
  
  def to_param
    "#{id}-#{name.gsub(/[^a-z0-9]+/i, '-').downcase}"
  end  
  
  validates_length_of :name, :within => 3..60
  validates_uniqueness_of :name
  
  # docs: http://www.practicalecommerce.com/blogs/post/122-Rails-Acts-As-State-Machine-Plugin
  acts_as_state_machine :initial => :published, :column => :status
  
  state :passive
  state :draft
  state :published, :enter => :do_publish
  state :deleted, :enter => :do_delete
  state :buried, :enter => :do_bury
  state :inactive
  
  event :publish do
    transitions :from => [:draft, :passive], :to => :published
  end
  
  event :delete do
    transitions :from => [:passive, :draft, :published], :to => :deleted
  end

  event :undelete do
    transitions :from => :deleted, :to => :published, :guard => Proc.new {|p| !p.published_at.blank? }
    transitions :from => :delete, :to => :draft 
  end
  
  event :bury do
    transitions :from => [:draft, :passive, :published, :deleted], :to => :buried
  end
  
  event :deactivate do
    transitions :from => [:draft, :published, :buried], :to => :inactive
  end
  
  cattr_reader :per_page
  @@per_page = 25
  
  def endorse(user,request=nil,partner=nil,referral=nil)
    return false if not user
    partner = nil if partner and partner.id == 1 # don't log partner if it's the default
    endorsement = self.endorsements.find_by_user_id(user.id)
    if not endorsement
      endorsement = Endorsement.new(:value => 1, :priority => self, :user => user, :partner => partner, :referral => referral)
      endorsement.ip_address = request.remote_ip if request
      endorsement.save
    elsif endorsement.is_down?
      endorsement.flip_up
      endorsement.save
    end
    if endorsement.is_replaced?
      endorsement.activate!
    end
    return endorsement
  end
  
  def oppose(user,request=nil,partner=nil,referral=nil)
    return false if not user
    partner = nil if partner and partner.id == 1 # don't log partner if it's the default
    endorsement = self.endorsements.find_by_user_id(user.id)
    if not endorsement
      endorsement = Endorsement.new(:value => -1, :priority => self, :user => user, :partner => partner, :referral => referral)
      endorsement.ip_address = request.remote_ip if request
      endorsement.save
    elsif endorsement.is_up?
      endorsement.flip_down
      endorsement.save
    end
    if endorsement.is_replaced?
      endorsement.activate!
    end
    return endorsement
  end  
  
  def is_obama_endorsed?
    obama_value == 1
  end
  
  def is_obama_opposed?
    obama_value == -1
  end
  
  def is_rising?
    position_7days_change > 0
  end  

  def is_falling?
    position_7days_change < 0
  end
  
  def is_controversial?
    return false unless down_endorsements_count > 0 and up_endorsements_count > 0
    (up_endorsements_count/down_endorsements_count) > 0.5 and (up_endorsements_count/down_endorsements_count) < 2
  end
  
  def is_buried?
    status == 'buried'
  end
  
  def is_top?
    return false if position == 0
    position < 101
  end
  
  def is_new?
    created_at > Time.now-(86400*7) or position_7days == 0    
  end
  
  def is_finished?
    obama_status > 1 or obama_status < 0
  end
  
  def is_failed?
    obama_status == -2
  end
  
  def is_successful?
    obama_status == 2
  end
  
  def is_compromised?
    obama_status == -1
  end
  
  def is_intheworks?
    obama_status == 1
  end  
  
  def position_7days_change_percent
    position_7days_change.to_f/(position+position_7days_change).to_f
  end
  
  def position_24hr_change_percent
    position_24hr_change.to_f/(position+position_24hr_change).to_f
  end  
  
  def position_30days_change_percent
    position_30days_change.to_f/(position+position_30days_change).to_f
  end  
  
  def value_name 
    if is_failed?
      'has failed'
    elsif is_successful?
      'was successful'
    elsif is_compromised?
      'is finished with a compromise'
    elsif is_intheworks?
      'is in the works'
    else
      'has not been finished yet'
    end
  end
  
  def failed!
    ActivityPriorityObamaStatusFailed.create(:priority => self, :user => user)
    self.status_changed_at = Time.now
    self.obama_status = -2
    self.status = 'inactive'
    self.change = nil
    self.save_with_validation(false)
    deactivate_endorsements  
  end
  
  def successful!
    ActivityPriorityObamaStatusSuccessful.create(:priority => self, :user => user)
    self.status_changed_at = Time.now
    self.obama_status = 2
    self.status = 'inactive'
    self.change = nil    
    self.save_with_validation(false)
    deactivate_endorsements
  end  
  
  def compromised!
    ActivityPriorityObamaStatusCompromised.create(:priority => self, :user => user)
    self.status_changed_at = Time.now
    self.obama_status = -1
    self.status = 'inactive'
    self.change = nil    
    self.save_with_validation(false)
    deactivate_endorsements
  end  
  
  def deactivate_endorsements
    for e in endorsements.active
      e.finish!
    end    
  end
  
  def reactivate!
    self.status = 'active'
    self.change = nil
    self.status_changed_at = Time.now
    self.obama_status = 0
    self.save_with_validation(false)
    for e in endorsements.active_and_inactive
      e.update_attribute(:status,'active')
      row = 0
      for ue in e.user.endorsements.active.by_position
        row += 1
        ue.update_attribute(:position,row) unless ue.position == row
        e.user.update_attribute(:top_endorsement_id,ue.id) if e.user.top_endorsement_id != ue.id and row == 1
      end      
    end
  end
  
  def intheworks!
    ActivityPriorityObamaStatusInTheWorks.create(:priority => self, :user => user)
    self.update_attribute(:status_changed_at, Time.now)
    self.update_attribute(:obama_status, 1)
  end  
  
  def obama_status_name
    return I18n.t('status.failed') if obama_status == -2
    return I18n.t('status.compromised') if obama_status == -1
    return I18n.t('status.unknown') if obama_status == 0 
    return I18n.t('status.intheworks') if obama_status == 1
    return I18n.t('status.successful') if obama_status == 2
  end
  
  def has_change?
    attribute_present?("change_id") and self.status != 'inactive' and change and not change.is_expired?
  end

  def has_search_query?
    attribute_present?("search_query")
  end
  
  def has_tags?
    attribute_present?("cached_issue_list")
  end
  
  def replaced?
    attribute_present?("change_id") and self.status == 'inactive'
  end
  
  def talking_point_text
    s = ''
    for p in points.published
      s += p.name + ' ' + p.content + ' '
    end
    return s
  end
  
  def movement_text
    s = ''
    if status == 'buried'
      return I18n.t('buried').capitalize
    elsif status == 'inactive'
      return I18n.t('inactive').capitalize
    elsif created_at > Time.now-86400
      return I18n.t('new').capitalize
    elsif position_24hr_change == 0 and position_7days_change == 0 and position_30days_change == 0
      return I18n.t('nochange').capitalize
    end
    s += '+' if position_24hr_change > 0
    s += '-' if position_24hr_change < 0    
    s += I18n.t('nochange') if position_24hr_change == 0
    s += position_24hr_change.abs.to_s unless position_24hr_change == 0
    s += ' today'
    s += ', +' if position_7days_change > 0
    s += ', -' if position_7days_change < 0    
    s += ', ' + I18n.t('nochange') if position_7days_change == 0
    s += position_7days_change.abs.to_s unless position_7days_change == 0
    s += ' this week'
    s += ', and +' if position_30days_change > 0
    s += ', and -' if position_30days_change < 0    
    s += ', and ' + I18n.t('nochange') if position_30days_change == 0
    s += position_30days_change.abs.to_s unless position_30days_change == 0
    s += ' this month'    
    s
  end
  
  def up_endorser_ids
    endorsements.active_and_inactive.endorsing.collect{|e|e.user_id.to_i}.uniq.compact
  end  
  def down_endorser_ids
    endorsements.active_and_inactive.opposing.collect{|e|e.user_id.to_i}.uniq.compact
  end
  def endorser_ids
    endorsements.active_and_inactive.collect{|e|e.user_id.to_i}.uniq.compact
  end
  def all_priority_ids_in_same_tags
    ts = Tagging.find(:all, :conditions => ["tag_id in (?) and taggable_type = 'Priority'",taggings.collect{|t|t.tag_id}.uniq.compact])
    return ts.collect{|t|t.taggable_id}.uniq.compact
  end
  memoize :up_endorser_ids, :down_endorser_ids, :endorser_ids, :all_priority_ids_in_same_tags
  
  
  #
  # NOTE: these three methods take into account what the people endorsed, it doesn't account for what they opposed, 
  # which is just as interesting
  #
  
  def endorsers_endorsed(limit=10)
    return [] unless has_tags? and up_endorsements_count > 2
    Priority.find_by_sql(["
    SELECT priorities.*, count(endorsements.id) as number, count(endorsements.id)/? as percentage, count(endorsements.id)/up_endorsements_count as score
    FROM endorsements,priorities
    where endorsements.priority_id = priorities.id
    and endorsements.priority_id <> ?
    and endorsements.status = 'active'
    and endorsements.value = 1
    and priorities.id in (#{all_priority_ids_in_same_tags.join(',')})
    and endorsements.user_id in (#{up_endorser_ids.join(',')})
    and priorities.status = 'published'
    group by priorities.id
    having count(endorsements.id)/? > 0.2
    order by score desc
    limit ?",up_endorsements_count,id,up_endorsements_count, limit])
  end  
  
  def opposers_endorsed(limit=10)
    return [] unless has_tags? and down_endorsements_count > 2    
    Priority.find_by_sql(["
    SELECT priorities.*, count(endorsements.id) as number, count(endorsements.id)/? as percentage, count(endorsements.id)/down_endorsements_count as score
    FROM endorsements,priorities
    where endorsements.priority_id = priorities.id
    and endorsements.priority_id <> ?
    and endorsements.status = 'active'
    and endorsements.value = 1
    and priorities.id in (#{all_priority_ids_in_same_tags.join(',')})
    and endorsements.user_id in (#{down_endorser_ids.join(',')})
    and priorities.status = 'published'    
    group by priorities.id
    having count(endorsements.id)/? > 0.2    
    order by score desc
    limit ?",down_endorsements_count,id,down_endorsements_count, limit])
  end  
  
  def undecideds_endorsed(limit=10)
    return [] unless has_tags? and endorsements_count > 2
    Priority.find_by_sql(["
    SELECT priorities.*, count(endorsements.id) as number, count(endorsements.id)/? as percentage, count(endorsements.id)/endorsements_count as score
    FROM endorsements,priorities
    where endorsements.priority_id = priorities.id
    and endorsements.priority_id <> ?
    and endorsements.status = 'active'
    and priorities.id in (#{all_priority_ids_in_same_tags.join(',')})
    and endorsements.user_id not in (#{endorser_ids.join(',')})
    and priorities.status = 'published'    
    group by priorities.id
    having count(endorsements.id)/? > 0.2        
    order by score desc
    limit ?",undecideds.size,id, undecideds.size, limit])
  end  
  
  def undecideds
    return [] unless has_tags? and endorsements_count > 2    
    User.find_by_sql("
    select distinct users.* 
    from users, endorsements
    where endorsements.user_id = users.id
    and endorsements.status = 'active'
    and endorsements.priority_id in (#{all_priority_ids_in_same_tags.join(',')})
    and endorsements.user_id not in (#{endorser_ids.join(',')})
    ")
  end
  
  def related(limit=10)
      Priority.find_by_sql(["SELECT priorities.*, count(*) as num_tags
      from taggings t1, taggings t2, priorities
      where 
      t1.taggable_type = 'Priority' and t1.taggable_id = ?
      and t1.tag_id = t2.tag_id
      and t2.taggable_type = 'Priority' and t2.taggable_id = priorities.id
      and t2.taggable_id <> ?
      and priorities.status = 'published'
      group by priorities.id
      order by num_tags desc, priorities.endorsements_count desc
      limit ?",id,id,limit])  
  end  
  
  def endorsements_by_day
    data = []
    labels = []
    numbers = endorsements.count(:group => "DATE_FORMAT(endorsements.created_at, '%Y-%m-%d')")
    numbers.each do |n|
      labels << n[0]
      data << n[1]
    end
    {:labels => labels, :data => data}
  end
  
  def rankings_by_day
    data = []
    labels = []
    numbers = rankings.average(:position, :group => "DATE_FORMAT(rankings.created_at, '%Y-%m-%d')")
    numbers.each do |n|
      labels << n[0]
      data << n[1].to_i
    end
    {:labels => labels, :data => data}
  end  
  
  def merge_into(p2_id,preserve=false,flip=0) #pass in the id of the priority to merge this one into.
    p2 = Priority.find(p2_id) # p2 is the priority that this one will be merged into
    for e in endorsements
      if not exists = p2.endorsements.find_by_user_id(e.user_id)
        e.priority_id = p2.id
        if flip == 1
          if e.value < 0
            e.value = 1 
          else
            e.value = -1
          end
        end   
        e.save_with_validation(false)     
      end
    end
    p2.reload
    size = p2.endorsements.active_and_inactive.length
    p2.update_attribute(:endorsements_count,size) if p2.endorsements_count != size
    size = p2.endorsements.active_and_inactive.endorsing.length
    p2.update_attribute(:up_endorsements_count,size) if p2.up_endorsements_count != size
    size = p2.endorsements.active_and_inactive.opposing.length
    p2.update_attribute(:down_endorsements_count,size) if p2.down_endorsements_count != size

    # look for the activities that should be removed entirely
    for a in Activity.find(:all, :conditions => ["priority_id = ? and type in ('ActivityPriorityDebut','ActivityPriorityNew','ActivityPriorityRenamed','ActivityPriorityFlag','ActivityPriorityFlagInappropriate','ActivityPriorityObamaStatusCompromised','ActivityPriorityObamaStatusFailed','ActivityPriorityObamaStatusIntheworks','ActivityPriorityObamaStatusSuccessful','ActivityPriorityRising1','ActivityIssuePriority1','ActivityIssuePriorityControversial1','ActivityIssuePriorityObama1','ActivityIssuePriorityRising1')",self.id])
      a.destroy
    end    
    #loop through the rest of the activities and move them over
    for a in activities
      if flip == 1
        for c in a.comments
          if c.is_opposer?
            c.is_opposer = 0
            c.is_endorser = 1
            c.save_with_validation(false)
          elsif c.is_endorser?
            c.is_opposer = 1
            c.is_endorser = 0
            c.save_with_validation(false)            
          end
        end
        if a.class == ActivityEndorsementNew
          a.update_attribute(:type,'ActivityOppositionNew')
        elsif a.class == ActivityOppositionNew
          a.update_attribute(:type,'ActivityEndorsementNew')
        elsif a.class == ActivityEndorsementDelete
          a.update_attribute(:type,'ActivityOppositionDelete')
        elsif a.class == ActivityOppositionDelete
          a.update_attribute(:type,'ActivityEndorsementDelete')
        elsif a.class == ActivityEndorsementReplaced
          a.update_attribute(:type,'ActivityOppositionReplaced')
        elsif a.class == ActivityOppositionReplaced 
          a.update_attribute(:type,'ActivityEndorsementReplaced')
        elsif a.class == ActivityEndorsementReplacedImplicit
          a.update_attribute(:type,'ActivityOppositionReplacedImplicit')
        elsif a.class == ActivityOppositionReplacedImplicit
          a.update_attribute(:type,'ActivityEndorsementReplacedImplicit')
        elsif a.class == ActivityEndorsementFlipped
          a.update_attribute(:type,'ActivityOppositionFlipped')
        elsif a.class == ActivityOppositionFlipped
          a.update_attribute(:type,'ActivityEndorsementFlipped')
        elsif a.class == ActivityEndorsementFlippedImplicit
          a.update_attribute(:type,'ActivityOppositionFlippedImplicit')
        elsif a.class == ActivityOppositionFlippedImplicit
          a.update_attribute(:type,'ActivityEndorsementFlippedImplicit')
        end
      end
      if preserve and (a.class.to_s[0..26] == 'ActivityPriorityAcquisition' or a.class.to_s[0..25] == 'ActivityCapitalAcquisition')
      else
        a.update_attribute(:priority_id,p2.id)
      end      
    end
    for a in ads
      a.update_attribute(:priority_id,p2.id)
    end    
    for point in points_with_deleted
      point.priority = p2
      if flip == 1
        if point.value > 0
          point.value = -1
        elsif point.value < 0
          point.value = 1
        end 
        # need to flip the helpful/unhelpful counts
        helpful = point.endorser_helpful_count
        unhelpful = point.endorser_unhelpful_count
        point.endorser_helpful_count = point.opposer_helpful_count
        point.endorser_unhelpful_count = point.opposer_unhelpful_count
        point.opposer_helpful_count = helpful
        point.opposer_unhelpful_count = unhelpful        
      end      
      point.save_with_validation(false)      
    end
    for document in documents
      document.priority = p2
      if flip == 1
        if document.value > 0
          document.value = -1
        elsif document.value < 0
          document.value = 1
        end 
        # need to flip the helpful/unhelpful counts
        helpful = document.endorser_helpful_count
        unhelpful = document.endorser_unhelpful_count
        document.endorser_helpful_count = document.opposer_helpful_count
        document.endorser_unhelpful_count = document.opposer_unhelpful_count
        document.opposer_helpful_count = helpful
        document.opposer_unhelpful_count = unhelpful        
      end      
      document.save_with_validation(false)      
    end
    for point in incoming_points
      if flip == 1
        point.other_priority = nil
      elsif point.other_priority == p2
        point.other_priority = nil
      else
        point.other_priority = p2
      end
      point.save_with_validation(false)
    end
    if not preserve # set preserve to true if you want to leave the Change and the original priority in tact, otherwise they will be deleted
      for c in changes_with_deleted
        c.destroy
      end
    end
    # find any issues they may be the top prioritiy for, and remove
    for tag in Tag.find(:all, :conditions => ["top_priority_id = ?",self.id])
      tag.update_attribute(:top_priority_id,nil)
    end
    # zap all old rankings for this priority
    Ranking.connection.execute("delete from rankings where priority_id = #{self.id.to_s}")
    self.reload
    self.destroy if not preserve
    return p2
  end
  
  def flip_into(p2_id,preserve=false) #pass in the id of the priority to flip this one into.  it'll turn up endorsements into down endorsements and vice versa
    merge_into(p2_id,1)
  end  
  
  def show_url
    'http://' + Government.current.base_url + '/priorities/' + to_param
  end
  
  private
  def do_publish
    self.published_at = Time.now
    ActivityPriorityNew.create(:user => user, :priority => self)    
  end
  
  def do_delete
    for e in endorsements
      e.delete!
    end
    self.deleted_at = Time.now
  end
  
  def do_undelete
    self.deleted_at = nil
  end  
  
  def do_bury
    # should probably send an email notification to the person who submitted it
    # but not doing anything for now.
  end
  
end
