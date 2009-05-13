class EmailTemplate < ActiveRecord::Base

  NAMES = ["welcome","invitation","new_password","notification_comment","notification_comment_flagged","notification_contact_joined","notification_invitation_accepted","notification_document_revision","notification_follower","notification_message","notification_point_revision","notification_priority_finished","notification_priority_flagged","notification_profile_bulletin","notification_warning1","notification_warning2","notification_warning3"]

  validates_presence_of :name
  validates_uniqueness_of :name

  after_save :clear_cache
  
  def clear_cache
    Rails.cache.delete(Government.current.short_name + '-' + name)
    return true
  end

  def EmailTemplate.fetch_liquid(name)
    liquid_blurb = Rails.cache.read(Government.current.short_name + "-email_template-" + name)
    if not liquid_blurb
      template = EmailTemplate.find_by_name(name)
      if template
        liquid_blurb = Liquid::Template.parse(template.content)
      else
        liquid_blurb = Liquid::Template.parse(EmailTemplate.fetch_default(name))
      end
      Rails.cache.write(Government.current.short_name + "-email_template-" + name, liquid_blurb)
    end
    return liquid_blurb
  end
  
  def EmailTemplate.fetch_default(name)
    File.open(RAILS_ROOT + "/app/views/email_templates/defaults/" + name + ".html.liquid", "r").read    
  end

  def EmailTemplate.fetch_subject_liquid(name)
    liquid_blurb = Rails.cache.read(Government.current.short_name + "-email_template_subject-" + name)
    if not liquid_blurb
      template = EmailTemplate.find_by_name(name)
      if template
        liquid_blurb = Liquid::Template.parse(template.subject)
      else
        liquid_blurb = Liquid::Template.parse(EmailTemplate.fetch_subject_default(name))
      end
      Rails.cache.write(Government.current.short_name + "-email_template_subject-" + name,liquid_blurb)
    end
    return liquid_blurb
  end

  def EmailTemplate.fetch_subject_default(name)
    File.open(RAILS_ROOT + "/app/views/email_templates/defaults/" + name + "_subject.html.liquid", "r").read    
  end

end
