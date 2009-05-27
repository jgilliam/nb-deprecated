class Widget < ActiveRecord::Base

  belongs_to :user
  belongs_to :tag

  def priorities_available
    a = Array.new
    if user
      a << [ "yours", I18n.t('priorities.yours.name') ]
      a << [ "yours_finished", I18n.t('priorities.yours_finished.name') ]
      a << [ "yours_created", I18n.t('priorities.yours_created.name') ]
      a << [ "network", I18n.t('priorities.network.name') ]
    end
    a << [ "top", I18n.t('priorities.top.name') ]
    a << [ "rising", I18n.t('priorities.rising.name') ]
    a << [ "falling", I18n.t('priorities.falling.name') ]
    a << [ "random", I18n.t('priorities.random.name') ]
    a << [ "newest", I18n.t('priorities.newest.name') ]
    a << [ "controversial", I18n.t('priorities.controversial.name') ]
    a << [ "finished", I18n.t('priorities.finished.name') ]
    if Government.current.has_official?
      a << [ "obama", I18n.t('priorities.official.title', :official_user_name => Government.current.official_user_short_name) ]
      a << [ "not_obama", I18n.t('priorities.not_official.title', :official_user_name => Government.current.official_user_short_name) ]
      a << [ "obama_opposed", I18n.t('priorities.official_opposed.title', :official_user_name => Government.current.official_user_short_name) ]
    end
    a
  end

  def discussions_available
    a = Array.new
    if user
      a << [ "your_discussions", I18n.t('news.your_discussions.name') ]
      a << [ "your_network_discussions", I18n.t('news.your_network_discussions.title') ]
      a << [ "your_priorities_discussions", I18n.t('news.your_priority_discussions.title') ]
      a << [ "your_priorities_created_discussions", I18n.t('news.your_priorities_created_discussions.title') ]
    end
    a << [ "discussions", I18n.t('news.discussions.name') ]
  end
  
  def points_available
    [
      [ "index", I18n.t('points.yours.title') ],
      [ "your_priorities", I18n.t('points.your_priorities.title')  ],                         
      [ "newest", I18n.t('points.newest.title')  ]
    ]
  end
  
  def charts_available
    [
      [ "charts_priority", I18n.t('charts.priority.short_name') ],
      [ "charts_user", I18n.t('priorities.yours.name') ]
    ]
  end

  def javascript_url
    if self.attribute_present?("tag_id")
      s = 'issues/' + tag.name.downcase + '/' + self.action_name
    else
      s = self.controller_name + "/" + self.action_name
    end
    if self.user
      Government.current.homepage_url + s + ".js?user_id=" + self.user.id.to_s + "&per_page=" + number.to_s
    else
      Government.current.homepage_url + s + ".js?per_page=" + number.to_s
    end
  end
  
  def javascript_code
    "<script src='" + javascript_url + "' type='text/javascript'></script>"
  end
  
end
