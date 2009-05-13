class ShownAd < ActiveRecord::Base

  named_scope :responded, :conditions => "shown_ads.value <> 0"
  named_scope :not_responded, :conditions => "shown_ads.value = 0"  
  named_scope :least_seen, :order => "shown_ads.seen_count asc"

  belongs_to :user
  belongs_to :ad

  after_create :increment_shown_count
  
  def increment_shown_count
    ad.increment!("shown_ads_count")
    if ad.shown_ads_count == ad.show_ads_count
      ad.finish!
    end
  end

  def request=(request)
    self.ip_address = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.referrer = request.env['HTTP_REFERER']
  end
  
  def is_up?
    self.value > 0
  end
  
  def is_down?
    self.value == -1
  end
  
  def is_skipped?
    self.value == -2
  end
  
  def has_response?
    self.value != 0
  end
  
end
