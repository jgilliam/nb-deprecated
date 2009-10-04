namespace :blast do  

  # This has not been updated to handle multiple databases, it really needs to go into the admin UI, and not here

  desc "queue the newsletter to go out this week"
  task :queue_newsletter => :environment do
    Government.current = Government.all.last
    name = '2009-03-22 newsletter'
    users = User.active.newsletter_subscribed.find(:all, :conditions => "created_at < date_add(now(), INTERVAL -10 HOUR)")
    for user in users
      if user.endorsements_count > 0
        if not BlastUserNewsletter.find_by_user_id_and_name(user.id,name)
          BlastUserNewsletter.create(:user => user, :name => name)
        end
      else
        if not BlastNewsletter.find_by_user_id_and_name(user.id,name)
          BlastNewsletter.create(:user => user, :name => name)
        end        
      end
    end
  end
  
  desc "queue a basic blast without the fair tax supporters"
  task :queue_blast_no_fairtax => :environment do
    Government.current = Government.all.last
    name = '2009-03-22 newsletter'
    users = User.find_by_sql("select * from users where is_newsletter_subscribed = 1 and status in ('active','pending') and id not in (select user_id from endorsements where priority_id = 763 and value > 0) and email is not null and email <> ''")
    for user in users
      if not BlastBasic.find_by_user_id_and_name(user.id,name)
        BlastBasic.create(:user => user, :name => name)
      end        
    end
  end  
  
  desc "queue a basic blast for people with more than 100 endorsements"
  task :queue_blast_100_endorsements => :environment do
    Government.current = Government.all.last    
    name = '2009-04-05 priority quiz'
    users = User.find_by_sql("select * from users where is_newsletter_subscribed = 1 and status in ('active','pending') and endorsements_count > 100 and email is not null and email <> ''")
    for user in users
      if not BlastBasic.find_by_user_id_and_name(user.id,name)
        BlastBasic.create(:user => user, :name => name)
      end        
    end
  end  
  
  desc "queue a basic blast with just the fair tax supporters"
  task :queue_blast_just_fairtax => :environment do
    Government.current = Government.all.last    
    name = '2009-03-22 newsletter'
    users = User.find_by_sql("select * from users where is_newsletter_subscribed = 1 and status in ('active','pending') and id in (select user_id from endorsements where priority_id = 763 and value > 0) and email is not null and email <> ''")
    for user in users
      if not BlastBasic.find_by_user_id_and_name(user.id,name)
        BlastBasic.create(:user => user, :name => name)
      end        
    end
  end
  
  desc "queue a newsletter without including the priorities"
  task :queue_newsletter_no_priorities => :environment do
    Government.current = Government.all.last    
    name = '2008-12-17 newsletter'
    users = User.active.newsletter_subscribed.find(:all, :conditions => "created_at < date_add(now(), INTERVAL -10 HOUR)")
    for user in users
      if not BlastNewsletter.find_by_user_id_and_name(user.id,name)
        BlastNewsletter.create(:user => user, :name => name)
      end        
    end
  end  
  
  desc "queue an email blast to folks who still need to add legislators"
  task :queue_legislators => :environment do
    Government.current = Government.all.last    
    name = '2008-03-25 legislators'
    users = User.active.newsletter_subscribed.find(:all, :conditions => "endorsements_count > 3 and constituents_count < 3 and not (constituents_count = 2 and state = 'Minnesota')")
    for user in users
      if not BlastLegislator.find_by_user_id_and_name(user.id,name)
        BlastLegislator.create(:user => user, :name => name)
      end        
    end
  end  
  
  desc "send blasts"
  task :send_emails => :environment do
    Government.current = Government.all.last    
    blasts = Blast.find(:all, :conditions => "status = 'pending'", :order => "rand()", :limit => 1000)
    for blast in blasts
      blast.send!
    end
  end
  
  desc "add your pictures"
  task :queue_add_pictures => :environment do
    Government.current = Government.all.last    
    name = 'add pictures - bailouts'
    @tag = Tag.find(31)
    users = @tag.subscribers
    for user in users
      if not BlastAddPicture.find_by_user_id_and_name(user.id,name)
        BlastAddPicture.create(:user => user, :name => name, :tag => @tag)
      end        
    end
  end  
  
  desc "queue alerts"
  task :queue_alerts => :environment do
    Government.current = Government.all.last    
    name = 'alert - healthcare change.gov'
    @tag = Tag.find(20)
    users = @tag.subscribers
    for user in users
      if not BlastAlert.find_by_user_id_and_name(user.id,name)
        BlastAlert.create(:user => user, :name => name, :tag => @tag)
      end        
    end
  end  
  
end