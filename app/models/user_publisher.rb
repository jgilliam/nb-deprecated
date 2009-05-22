class UserPublisher < Facebooker::Rails::Publisher

  # The new message templates are supported as well
  # First, create a method that contains your templates:
  # You may include multiple one line story templates and short story templates but only one full story template
  #  Your most specific template should be first
  #
  # Before using, you must register your template by calling register. For this example
  #  You would call UserPublisher.register_endorsement
  #  Registering the template will store the template id returned from Facebook in the
  # facebook_templates table that is created when you create your first publisher
  
  def endorsement_template
    one_line_story_template "{*actor*} endorsed <a href='{*priority_url*}'>{*priority_name*}</a> at priority {*position*} on <a href='{*government_url*}'>{*government_name*}</a>"
    short_story_template "{*actor*} endorsed <a href='{*priority_url*}'>{*priority_name*}</a> at priority {*position*} on <a href='{*government_url*}'>{*government_name*}</a>", render(:partial => "priority")
    action_links action_link("Learn more","{*priority_url*}")
  end

  # To send a registered template, you need to create a method to set the data
  # The publisher will look up the template id from the facebook_templates table
  def endorsement(facebook_session, endorsement, priority)
    send_as :user_action
    from facebook_session.user
    story_size SHORT # ONE_LINE, SHORT or FULL
    data :priority_url => priority.show_url, :priority_name => priority.name, :position => endorsement.position, :government_url => Government.current.homepage_url, :government_name => Government.current.name, :endorsers => priority.up_endorsements_count, :opposers => priority.down_endorsements_count, :rank => priority.position
  end
  
  def opposition_template
    one_line_story_template "{*actor*} opposed <a href='{*priority_url*}'>{*priority_name*}</a> at priority {*position*} on <a href='{*government_url*}'>{*government_name*}</a>"
    short_story_template "{*actor*} opposed <a href='{*priority_url*}'>{*priority_name*}</a> at priority {*position*} on <a href='{*government_url*}'>{*government_name*}</a>", render(:partial => "priority")
    action_links action_link("Learn more","{*priority_url*}")
  end

  # To send a registered template, you need to create a method to set the data
  # The publisher will look up the template id from the facebook_templates table
  def opposition(facebook_session, endorsement, priority)
    send_as :user_action
    from facebook_session.user
    story_size SHORT # ONE_LINE, SHORT or FULL
    data :priority_url => priority.show_url, :priority_name => priority.name, :position => endorsement.position, :government_url => Government.current.homepage_url, :government_name => Government.current.name, :endorsers => priority.up_endorsements_count, :opposers => priority.down_endorsements_count, :rank => priority.position
  end  
  
  def comment_template
    one_line_story_template "{*actor*} <a href='{*comment_url*}'>commented</a> on <a href='{*object_url*}'>{*object_name*}</a> at <a href='{*government_url*}'>{*government_name*}</a>"
    short_story_template "{*actor*} <a href='{*comment_url*}'>commented</a> on <a href='{*object_url*}'>{*object_name*}</a> at <a href='{*government_url*}'>{*government_name*}</a>", "{*short_comment_body*}"
    full_story_template "{*actor*} <a href='{*comment_url*}'>commented</a> on <a href='{*object_url*}'>{*object_name*}</a> at <a href='{*government_url*}'>{*government_name*}</a>", "{*comment_body*}"  
    action_links action_link("Reply","{*comment_url*}")      
  end
  
  def comment(facebook_session, comment, activity)
    send_as :user_action
    from facebook_session.user
    story_size SHORT # ONE_LINE, SHORT or FULL
    
    if activity.has_point?
      object_url = activity.point.show_url
      object_name = activity.point.name
    elsif activity.has_document?
      object_url = activity.document.show_url
      object_name = activity.document.name
    elsif activity.has_priority?
      object_url = activity.priority.show_url
      object_name = activity.priority.name
    else
      object_url = comment.show_url
      object_name = activity.name
    end
    
    data :object_url => object_url, :object_name => object_name, :comment_url => comment.show_url, :government_url => Government.current.homepage_url, :government_name => Government.current.name, :short_comment_body => truncate(comment.content, :length => 400), :comment_body => comment.content  
    
  end

  def point_template
    one_line_story_template "{*actor*} added a <a href='{*point_url*}'>talking point</a> to <a href='{*priority_url*}'>{*priority_name*}</a> at <a href='{*government_url*}'>{*government_name*}</a>"
    short_story_template "{*actor*} added a <a href='{*point_url*}'>talking point</a> to <a href='{*priority_url*}'>{*priority_name*}</a> at <a href='{*government_url*}'>{*government_name*}</a>", render(:partial => "title_and_body")
    action_links action_link("Learn more","{*point_url*}")      
  end 
  
  def point(facebook_session, point, priority)
    send_as :user_action
    from facebook_session.user
    story_size SHORT # ONE_LINE, SHORT or FULL
    data :priority_url => priority.show_url, :priority_name => priority.name, :point_url => point.show_url, :government_url => Government.current.homepage_url, :government_name => Government.current.name, :body => point.content, :source => point.website_link, :title => point.name_with_type
  end
  
  def document_template
    one_line_story_template "{*actor*} added a <a href='{*document_url*}'>document</a> to <a href='{*priority_url*}'>{*priority_name*}</a> at <a href='{*government_url*}'>{*government_name*}</a>"
    short_story_template "{*actor*} added a <a href='{*document_url*}'>document</a> to <a href='{*priority_url*}'>{*priority_name*}</a> at <a href='{*government_url*}'>{*government_name*}</a>", render(:partial => "title_and_body")
    action_links action_link("Learn more","{*document_url*}")  
  end
  
  def document(facebook_session, document, priority)
    send_as :user_action
    from facebook_session.user
    story_size SHORT # ONE_LINE, SHORT or FULL
    data :priority_url => priority.show_url, :priority_name => priority.name, :document_url => document.show_url, :government_url => Government.current.homepage_url, :government_name => Government.current.name, :body => truncate(document.content, :length => 400), :title => document.name_with_type
  end  
  
end
