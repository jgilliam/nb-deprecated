# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def time_ago(time, options = {})
    if request.xhr?
      distance_of_time_in_words_to_now(time) + ' ago'
    else
      options[:class] ||= "timeago"
      content_tag(:abbr, time.to_s, options.merge(:title => time.getutc.iso8601)) if time
    end
  end  
  
  def flash_div *keys
    keys.collect { |key| content_tag(:div, link_to("x","#", :class => "close_notify") + content_tag(:span, flash[key]), :class => "flash_#{key}") if flash[key] }.join
  end

  def revisions_sentence(user)
    return "" if user.points_count+user.documents_count+user.revisions_count == 0
    r = []
    r << link_to(t('menu.briefing.points', :count => user.points_count), points_user_url(user)) if user.points_count > 0 
    r << link_to(t('menu.briefing.documents', :count => user.documents_count), documents_user_url(user)) if user.documents_count > 0     
    r << t('menu.briefing.revisions', :count => user.revisions_count) if user.revisions_count > 0
    t('document.revision.sentence', :sentence => r.to_sentence)
  end
  
  def notifications_sentence(notifications)
    return "" if notifications.empty?
    r = []
		for u in notifications
		  if u[0] == 'NotificationWarning1'
		    r << link_to(t('notification.warning1.link'), :controller => "inbox", :action => "notifications")
  		elsif u[0] == 'NotificationWarning2'
  		  r << link_to(t('notification.warning2.link'), :controller => "inbox", :action => "notifications")
    	elsif u[0] == 'NotificationWarning3'
    		r << link_to(t('notification.warning3.link'), :controller => "inbox", :action => "notifications")  		    		    
			elsif u[0] == 'NotificationMessage' 
				r << t('notification.message.link',:count => u[1], :sentence =>   messages_sentence(current_user.received_notifications.messages.unread.count(:group => [:sender], :order => "count_all desc")))
			elsif u[0] == 'NotificationCommentFlagged'
			  r << link_to(t('notification.comment.flagged.link', :count => u[1]), :controller => "inbox", :action => "notifications")
			elsif u[0] == 'NotificationPriorityFlagged'
			  r << link_to(t('notification.priority.flagged.link', :count => u[1]), :controller => "inbox", :action => "notifications")			  
			elsif u[0] == 'NotificationComment' 
				r << link_to(t('notification.comment.new.link', :count => u[1]), :controller => "news", :action => "your_discussions") 
			elsif u[0] == 'NotificationProfileBulletin'
			  r << link_to(t('notification.profile.bulletin.link', :count => u[1]), current_user)
			elsif u[0] == 'NotificationFollower' 
				r << link_to(t('notification.follower.link', :count => u[1]), :controller => "inbox", :action => "notifications") 			
			elsif u[0] == 'NotificationInvitationAccepted' 
				r << link_to(t('notification.invitation.accepted.link', :count => u[1]), :controller => "inbox", :action => "notifications")
			elsif u[0] == 'NotificationContactJoined' 
				r << link_to(t('notification.contact.joined.link', :count => u[1]), :controller => "inbox", :action => "notifications")
			elsif u[0] == 'NotificationDocumentRevision' 
				r << link_to(t('notification.document.revision.link', :count => u[1]), :controller => "inbox", :action => "notifications")
			elsif u[0] == 'NotificationPointRevision' 
				r << link_to(t('notification.point.revision.link', :count => u[1]), :controller => "inbox", :action => "notifications")
			elsif u[0] == 'NotificationPriorityFinished' 
				r << link_to(t('notification.priority.finished.link', :count => u[1]), yours_finished_priorities_url)
			elsif u[0] == 'NotificationChangeVote' 
				r << link_to(t('notification.change.vote.link', :count => u[1]), :controller => "news", :action => "changes_voting")
			end 
		end     
	  return "" if r.empty?
		t('notification.sentence', :sentence => r.to_sentence)
  end
  
  def messages_sentence(messages)
    return "" if messages.empty?
    r = []
    for m in messages
      r << link_to(m[0].name, user_messages_url(m[0]))
    end
    r.to_sentence
  end
  
  def relationship_sentence(relationships)
    return "" if relationships.empty?
    r = []
		for relationship in relationships
			if relationship.class == RelationshipUndecidedEndorsed
				r << t('priorities.relationship.undeclared', :percentage => number_to_percentage(relationship.percentage, :precision => 0))
			elsif relationship.class == RelationshipOpposerEndorsed
				r << t('priorities.relationship.opposers', :percentage => number_to_percentage(relationship.percentage, :precision => 0))			  
			elsif relationship.class == RelationshipEndorserEndorsed
				r << t('priorities.relationship.endorsers', :percentage => number_to_percentage(relationship.percentage, :precision => 0))			  
			end
		end
		t('priorities.relationship.name', :sentence => r.to_sentence)
  end
  
  def tags_sentence(list)
    r = []
    for tag_name in list.split(', ')
      tag = current_tags.detect{|t| t.name == tag_name}
			r << link_to(tag.title, :controller => "issues", :slug => tag.slug) if tag
		end
		r.to_sentence
  end
  
  def relationship_tags_sentence(list)
		t('priorities.relationship.tags_sentence', :sentence => tags_sentence(list))
  end
  
  def rss_url(url)
    return "" unless url
    s = '<span class="rss_feed"><a href="' + url + '">'
    s += image_tag "feed-icon-14x14.png", :size => "14x14", :border => 0
    s += '</a> <a href="' + url + '">' + t('feeds.rss') + '</a></span>'
    return s
  end
  
  def agenda_change(user,period,precision=2)
    if period == '7days'
		  user_last = user.index_7days_change*100
		elsif period == '24hr'
		  user_last = user.index_24hr_change*100
		elsif period == '30days'
		  user_last = user.index_30days_change*100
		end
		if user_last < 0.005 and user_last > -0.005
		  s = '<div class="nochange">' + t('unch') + '</div>'
		elsif user_last.abs == user_last
		  s = '<div class="gainer">+'
		  s += number_to_percentage(user_last, :precision => precision)
		  s += '</div>'
		else
		  s = '<div class="loser">'
		  s += number_to_percentage(user_last, :precision => precision)
		  s += '</div>'
		end
		return s
  end
  
  def official_status(priority)
  	if priority.is_failed?
  		'<span class="opposed">' + priority.obama_status_name + '</span>'
  	elsif priority.is_successful?
  		'<span class="endorsed">' + priority.obama_status_name + '</span>'
  	elsif priority.is_compromised?
  		'<span class="compromised">' + priority.obama_status_name + '</span>'
  	elsif priority.is_intheworks?
  		'<span>' + priority.obama_status_name + '</span>'
  	end
  end
  
  def liquidize(content, arguments)
    Liquid::Template.parse(content).render(arguments, :filters => [LiquidFilters])
  end

end