class Blurb < ActiveRecord::Base

  NAMES = ["intro", "header", "footer", "rules", "warnings", "signup_intro", "invite_intro", "not_verified", "partner_intro", "signup_quick", "privacy", "faq", "about", "textile", "ad_intro", "ad_new", "acquisition_new", "document_new", "docs_needed_intro", "point_new", "point_revision_new", "points_needed_intro", "tags_intro", "your_network_intro", "sorting_instruct", "sorting_instruct_adv", "overview_more", "network_intro", "account_delete", "legislators_intro", "people_you_know_intro", "about_menu_extra"]

  validates_presence_of :name
  validates_uniqueness_of :name

  after_save :clear_cache
  
  def clear_cache
    Rails.cache.delete('blurb-' + name)
    return true
  end

  def Blurb.fetch_liquid(name)
    liquid_blurb = Rails.cache.read("blurb-" + name)
    if not liquid_blurb
      blurb = Blurb.find_by_name(name)
      if blurb
        liquid_blurb = Liquid::Template.parse(blurb.content)
      else
        liquid_blurb = Liquid::Template.parse(Blurb.fetch_default(name))
      end
      Rails.cache.write("blurb-" + name,liquid_blurb)
    end
    return liquid_blurb
  end

  def Blurb.fetch_default(name)
    File.open(RAILS_ROOT + "/app/views/blurbs/defaults/" + name + ".html.liquid", "r").read    
  end

end
