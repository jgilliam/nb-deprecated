namespace :sunlight do  
  
  desc "update legislators from sunlight api"
  task :legislators => :environment do
    for govt in Government.active.all
      govt.switch_db
      for state in State::NAMES
        for s in Sunlight::Legislator.all_where(:state => state[1])
          l = Legislator.find_or_create_by_firstname_and_lastname(s.firstname,s.lastname)
          if s.nickname.any?
            l.name = s.nickname + " " + s.lastname
          else
            l.name = s.firstname + " " + s.lastname
          end
          l.fullname = s.title + '. '
          l.fullname += s.firstname + ' '
          l.fullname += s.middlename + ' ' if s.middlename.any?
          l.fullname += s.lastname
          l.fullname += ', ' + s.name_suffix if s.name_suffix.any?
        
          l.nickname = s.nickname
          l.title = s.title
          l.firstname = s.firstname
          l.middlename = s.middlename
          l.lastname = s.lastname
          l.name_suffix = s.name_suffix
          l.gender = s.gender
          l.senate_class = s.senate_class
          l.congress_office = s.congress_office
          l.party = s.party
          l.state = s.state
          l.district = s.district
          l.in_office = s.in_office
          l.govtrack_id = s.govtrack_id
          l.votesmart_id = s.votesmart_id
          l.fec_id = s.fec_id
          l.crp_id = s.crp_id
          l.bioguide_id = s.bioguide_id
          l.phone = s.phone
          l.fax = s.fax
          l.email = s.email
          l.webform = s.webform
          l.website = s.website
          l.twitter_id = s.twitter_id
          l.congresspedia_url = s.congresspedia_url
          l.youtube_url = s.youtube_url
          l.last_crawled_at = Time.now
          l.save
        end
      end
    end
  end
  
  desc "attach existing users to legislators"
  task :users => :environment do
    for govt in Government.active.all
      govt.switch_db
      for u in User.active.find(:all, :conditions => "zip <> '' and zip is not null and constituents_count < 3")
        num = u.attach_legislators
        puts u.name + ' - ' + num.to_s
      end
    end
  end

end