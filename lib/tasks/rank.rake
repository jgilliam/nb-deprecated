namespace :rank do  
  
  desc "ranks all the priorities in the database with any endorsements"
  task :priorities => :environment do
    for govt in Government.active.all
      govt.switch_db    
      # get the last version # for the different time lengths
      v = Ranking.find(:all, :select => "max(version) as version")[0]
      if v
        v = v.version || 0
        v+=1
      else
        v = 1
      end
      oldest = Ranking.find(:all, :select => "max(version) as version")[0].version
      v_1hr = oldest
      v_24hr = oldest
      r = Ranking.find(:all, :select => "max(version) as version", :conditions => "created_at < date_add(now(), INTERVAL -1 HOUR)")[0]
      v_1hr = r.version if r
      r = Ranking.find(:all, :select => "max(version) as version", :conditions => "created_at < date_add(now(), INTERVAL -1 DAY)")[0]
      v_24hr = r.version if r

      priorities = Priority.find_by_sql("
          select priorities.*, sum(((101-endorsements.position)*endorsements.value)*users.score) as number
          from users,endorsements,priorities
          where endorsements.user_id = users.id
          and endorsements.priority_id = priorities.id
          and priorities.status = 'published'
          and endorsements.status = 'active' and endorsements.position < 101
          group by priority_id
          order by number desc")
      i = 0
      for p in priorities
        p.score = p.number
        first_time = false
        i = i + 1
        p.position = i
      
        r = p.rankings.find_by_version(v_1hr)
        if r # it's in that version
          p.position_1hr = r.position
        else # not in that version, find the oldest one we can
          r = p.rankings.find(:all, :conditions => ["version < ?",v_1hr],:order => "version asc", :limit => 1)[0]
          if r
            p.position_1hr = r.position
          else # this is the first time they've been ranked
            p.position_1hr = p.position
            first_time = true
          end
        end
      
        p.position_1hr_change = p.position_1hr - i 
        r = p.rankings.find_by_version(v_24hr)
        if r # in that version
          p.position_24hr = r.position
          p.position_24hr_change = p.position_24hr - i          
        else # didn't exist yet, so let's find the oldest one we can
          r = p.rankings.find(:all, :conditions => ["version < ?",v_24hr],:order => "version asc", :limit => 1)[0]
          p.position_24hr = 0
          p.position_24hr_change = 0
        end   
        
        date = Time.now-5.hours-7.days
        c = p.charts.find_by_date_year_and_date_month_and_date_day(date.year,date.month,date.day)
        if c
          p.position_7days = c.position
          p.position_7days_change = p.position_7days - i   
        else
          p.position_7days = 0
          p.position_7days_change = 0
        end      
      
        date = Time.now-5.hours-30.days
        c = p.charts.find_by_date_year_and_date_month_and_date_day(date.year,date.month,date.day)
        if c
          p.position_30days = c.position
          p.position_30days_change = p.position_30days - i   
        else
          p.position_30days = 0
          p.position_30days_change = 0
        end      
      
        p.save_with_validation(false)
        r = Ranking.create(:version => v, :priority => p, :position => i, :endorsements_count => p.endorsements_count)
      end
      Priority.connection.execute("update priorities set position = 0 where endorsements_count = 0;")
      # check if there's a new fastest rising priority
      rising = Priority.published.rising.all[0]
      if rising
        ActivityPriorityRising1.create(:priority => rising) unless ActivityPriorityRising1.find_by_priority_id(rising.id)
      end
    end
  end
  
  desc "determines any changes in the #1 priority for an issue, and updates the # of distinct endorsers and opposers across the entire issue"
  task :issues => :environment do
    for govt in Government.active.all
      govt.switch_db
      keep = []
      # get the number of endorsers on the issue
      tags = Tag.find_by_sql("SELECT tags.*, count(distinct endorsements.user_id) as num_endorsers
      FROM tags,taggings,endorsements
      where 
      taggings.taggable_id = endorsements.priority_id
      and taggable_type = 'Priority'
      and taggings.tag_id = tags.id
      and endorsements.status = 'active'
      and endorsements.value > 0
      group by taggings.tag_id")
      for tag in tags
        keep << tag.id
        priorities = tag.priorities.published.top_rank # figure out the top priority while we're at it
        tag.priorities_count = priorities.size      
        if priorities.any?
          if tag.top_priority_id != priorities[0].id # new top priority
            ActivityIssuePriority1.create(:tag => tag, :priority_id => priorities[0].id)
            tag.top_priority_id = priorities[0].id
          end
          controversial = tag.priorities.published.controversial
          if controversial.any? and tag.controversial_priority_id != controversial[0].id
            ActivityIssuePriorityControversial1.create(:tag => tag, :priority_id => controversial[0].id)
            tag.controversial_priority_id = controversial[0].id
          elsif controversial.empty?
            tag.controversial_priority_id = nil
          end
          rising = tag.priorities.published.rising
          if rising.any? and tag.rising_priority_id != rising[0].id
            ActivityIssuePriorityRising1.create(:tag => tag, :priority_id => rising[0].id)
            tag.rising_priority_id = rising[0].id
          elsif rising.empty?
            tag.rising_priority_id = nil
          end 
          obama = tag.priorities.published.obama_endorsed
          if obama.any? and tag.obama_priority_id != obama[0].id
            ActivityIssuePriorityObama1.create(:tag => tag, :priority_id => obama[0].id)
            tag.obama_priority_id = obama[0].id
          elsif obama.empty?
            tag.obama_priority_id = nil
          end
        else
          tag.top_priority_id = nil
          tag.controversial_priority_id = nil
          tag.rising_priority_id = nil
          tag.obama_priority_id = nil
          tag.new_priority_id = nil          
        end
        tag.up_endorsers_count = tag.num_endorsers
        tag.save_with_validation(false)
      end
      # get the number of opposers on the issue
      tags = Tag.find_by_sql("SELECT tags.*, count(distinct endorsements.user_id) as num_opposers
      FROM tags,taggings,endorsements
      where 
      taggings.taggable_id = endorsements.priority_id
      and taggable_type = 'Priority'
      and taggings.tag_id = tags.id
      and endorsements.status = 'active'
      and endorsements.value < 0
      group by taggings.tag_id")    
      for tag in tags
        keep << tag.id
        tag.update_attribute(:down_endorsers_count,tag.num_opposers) unless tag.down_endorsers_count == tag.num_opposers
      end
      Tag.connection.execute("update tags set priorities_count = 0 where id not in (#{keep.uniq.compact.join(',')})")
    end
  end
  
  desc "applies vote rank algorithm to users"
  task :user_votes => :environment do
    for govt in Government.active.all
      govt.switch_db    
      # update the # of issues they've UP endorsed
      users = User.find_by_sql("SELECT users.*, count(distinct taggings.tag_id) as num_issues
      FROM taggings,endorsements, users
      where taggings.taggable_id = endorsements.priority_id
      and taggings.taggable_type = 'Priority'
      and endorsements.user_id = users.id
      and endorsements.value > 0
      and endorsements.status = 'active'
      group by endorsements.user_id")
      for u in users
        u.update_attribute("up_issues_count",u.num_issues) unless u.up_issues_count == u.num_issues
      end
      # update the # of issues they've DOWN endorsed
      users = User.find_by_sql("SELECT users.*, count(distinct taggings.tag_id) as num_issues
      FROM taggings,endorsements, users
      where taggings.taggable_id = endorsements.priority_id
      and taggings.taggable_type = 'Priority'
      and endorsements.user_id = users.id
      and endorsements.value < 0
      and endorsements.status = 'active'
      group by endorsements.user_id")
      for u in users
        u.update_attribute("down_issues_count",u.num_issues) unless u.down_issues_count == u.num_issues
      end
      users = User.find(:all, :conditions => "status in ('active','pending')")
      for u in users
        u.update_attribute(:score,u.calculate_score)
      end
    end
  end
  
  
  desc "ranks all users with any political capital"
  task :users => :environment do
    for govt in Government.active.all
      govt.switch_db    
      # get the last version # for the different time lengths
      v = UserRanking.find(:all, :select => "max(version) as version")[0]
      if v and v.version
        v = v.version || 0
        v+=1
      else
        v = 1
      end
      oldest = UserRanking.find(:all, :select => "max(version) as version")[0].version
      v_1hr = oldest
      v_24hr = oldest
      r = UserRanking.find(:all, :select => "max(version) as version", :conditions => "created_at < date_add(now(), INTERVAL -1 HOUR)")[0]
      v_1hr = r.version if r
      r = UserRanking.find(:all, :select => "max(version) as version", :conditions => "created_at < date_add(now(), INTERVAL -1 DAY)")[0]
      v_24hr = r.version if r

      users = User.active.by_capital.find(:all, :conditions => "capitals_count > 0 and endorsements_count > 0")
      i = 0
      for u in users
        first_time = false
        i = i + 1
        u.position = i
        r = u.rankings.find_by_version(v_1hr)
        if r # it's in that version
          u.position_1hr = r.position
        else # not in that version, find the oldest one we can
          r = u.rankings.find(:all, :conditions => ["version < ?",v_1hr],:order => "version asc", :limit => 1)[0]
          if r
            u.position_1hr = r.position
          else # this is the first time they've been ranked
            u.position_1hr = u.position
            first_time = true
          end
        end
        u.position_1hr_change = u.position_1hr - i 
        r = u.rankings.find_by_version(v_24hr)
        if r # in that version
          u.position_24hr = r.position
        else # didn't exist yet, so let's find the oldest one we can
          r = u.rankings.find(:all, :conditions => ["version < ?",v_24hr],:order => "version asc", :limit => 1)[0]
          u.position_24hr = r.position if r
          u.position_24hr = i unless r
        end   
        u.position_24hr_change = u.position_24hr - i    
      
        date = Time.now-5.hours-7.days
        c = u.charts.find_by_date_year_and_date_month_and_date_day(date.year,date.month,date.day)
        if c
          u.position_7days = c.position
          u.position_7days_change = u.position_7days - i   
        else
          u.position_7days = 0
          u.position_7days_change = 0
        end      
      
        date = Time.now-5.hours-30.days
        c = u.charts.find_by_date_year_and_date_month_and_date_day(date.year,date.month,date.day)
        if c
          u.position_30days = c.position
          u.position_30days_change = u.position_30days - i   
        else
          u.position_30days = 0
          u.position_30days_change = 0
        end      
        u.save_with_validation(false)
        r = UserRanking.create(:version => v, :user => u, :position => i, :capitals_count => u.capitals_count)
      end
      User.connection.execute("update users set position = 0 where capitals_count = 0;")
    end
  end  
  
  desc "ditches anything older in the rankings/user_rankings tables than 8 days"
  task :thinner => :environment do
    for govt in Government.active.all
      govt.switch_db    
      Ranking.connection.execute("delete from rankings where created_at < date_add(now(), INTERVAL -8 DAY)")
      UserRanking.connection.execute("delete from user_rankings where created_at < date_add(now(), INTERVAL -8 DAY)")
    end
  end
  
end