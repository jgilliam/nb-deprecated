namespace :rank do  
  
  desc "ranks all the priorities in the database with any endorsements. this should be run AFTER rake rank:branch_endorsements so governments with branches are ranked properly"
  task :priorities => :environment do
    for govt in Government.active.without_branches.all
      current_time = Time.now
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

      if govt.is_branches?
        priorities = Priority.find_by_sql("
            select priorities.*, branch_endorsements.priority_id, sum(branches.rank_factor*branch_endorsements.score) as number 
            from priorities, branch_endorsements, branches
            where branch_endorsements.branch_id = branches.id and branch_endorsements.priority_id = priorities.id
            and priorities.status = 'published'
            group by branch_endorsements.priority_id
            order by aggregate_score desc")
      else
        priorities = Priority.find_by_sql("
            select priorities.*, sum(((#{Endorsement.max_position+1}-endorsements.position)*endorsements.value)*users.score) as number
            from users,endorsements,priorities
            where endorsements.user_id = users.id
            and endorsements.priority_id = priorities.id
            and priorities.status = 'published'
            and endorsements.status = 'active' and endorsements.position <= #{Endorsement.max_position}
            group by priority_id
            order by number desc")
      end
      
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
        
        Priority.update_all("position = #{p.position}, score = #{p.score}, position_1hr = #{p.position_1hr}, position_1hr_change = #{p.position_1hr_change}, position_24hr = #{p.position_24hr}, position_24hr_change = #{p.position_24hr_change}, position_7days = #{p.position_7days}, position_7days_change = #{p.position_7days_change}, position_30days = #{p.position_30days}, position_30days_change = #{p.position_30days_change}", ["id = ?",p.id])
        r = Ranking.create(:version => v, :priority => p, :position => i, :endorsements_count => p.endorsements_count)
      end
      Priority.connection.execute("update priorities set position = 0 where endorsements_count = 0;")
      
      # check if there's a new fastest rising priority
      rising = Priority.published.rising.all[0]
      ActivityPriorityRising1.find_or_create_by_priority_id(rising.id) if rising
    end
    puts 'seconds spent: ' + (Time.now-current_time).to_s
  end
  
  desc "ranks all the branch endorsements"
  task :branch_endorsements => :environment do
    for govt in Government.active.with_branches.all
      govt.switch_db
      govt.update_user_default_branch
      for branch in Branch.all
        # get the last version # for the different time lengths
        v = branch.endorsement_rankings.find(:all, :select => "max(version) as version")[0]
        if v
          v = v.version || 0
          v+=1
        else
          v = 1
        end
        oldest = branch.endorsement_rankings.find(:all, :select => "max(version) as version")[0].version
        v_1hr = oldest
        v_24hr = oldest
        r = branch.endorsement_rankings.find(:all, :select => "max(version) as version", :conditions => "branch_endorsement_rankings.created_at < date_add(now(), INTERVAL -1 HOUR)")[0]
        v_1hr = r.version if r
        r = branch.endorsement_rankings.find(:all, :select => "max(version) as version", :conditions => "branch_endorsement_rankings.created_at < date_add(now(), INTERVAL -1 DAY)")[0]
        v_24hr = r.version if r

        endorsement_scores = Endorsement.active.find(:all, 
          :select => "endorsements.priority_id, sum(endorsements.score) as number, count(*) as endorsements_number", 
          :joins => "endorsements INNER JOIN priorities ON priorities.id = endorsements.priority_id", 
          :conditions => ["endorsements.user_id in (?)",branch.user_ids], 
          :group => "endorsements.priority_id",       
          :order => "number desc")
        i = 0
        for e in endorsement_scores
          p = branch.endorsements.find_or_create_by_priority_id(e.priority_id.to_i)
          p.endorsements_count = e.endorsements_number.to_i
          p.update_counts if p.endorsements_count != p.up_endorsements_count+p.down_endorsements_count
          p.score = e.number.to_i
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
          r = BranchEndorsementRanking.create(:version => v, :branch_endorsement => p, :position => i, :endorsements_count => p.endorsements_count)
        end
      
        # check if there's a new fastest rising priority for this branch
        #rising = BranchEndorsement.rising.all[0]
        #ActivityPriorityRising1.find_or_create_by_priority_id(rising.id) if rising
      end
      BranchEndorsement.connection.execute("delete from branch_endorsements where endorsements_count = 0;")      
      
      # adjusts the boost factor for branches with less users, so it's equivalent to the largest branch
      branches = Branch.all
      max_users = branches.collect{|b| b.users_count}.sort.last
      for branch in branches
        if branch.users_count == 0
          rank_factor = 0 
        else
          rank_factor = max_users.to_f / branch.users_count.to_f
        end
        branch.update_attribute(:rank_factor, rank_factor) if branch.rank_factor != rank_factor
      end
      
    end
  end  
  
  desc "determines any changes in the #1 priority for an issue, and updates the # of distinct endorsers and opposers across the entire issue"
  task :issues => :environment do
    for govt in Government.active.all
      govt.switch_db
      next if Tag.count == 0
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
      if keep.any?
        Tag.connection.execute("update tags set up_endorsers_count = 0, down_endorsers_count = 0 where id not in (#{keep.uniq.compact.join(',')})")
      end
    end
  end
  
  desc "applies vote rank algorithm to users"
  task :user_votes => :environment do
    for govt in Government.active.all
      govt.switch_db    
      if govt.is_tags?
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
      end
      users = User.active.all
      for u in users
        new_score = u.calculate_score
        u.update_attribute(:score,new_score) if u.score != new_score
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
      v_24hr = oldest
      r = UserRanking.find(:all, :select => "max(version) as version", :conditions => "created_at < date_add(now(), INTERVAL -1 DAY)")[0]
      v_24hr = r.version if r

      users = User.active.by_capital.find(:all, :conditions => "capitals_count > 0 and endorsements_count > 0")
      i = 0
      for u in users
        first_time = false
        i = i + 1
        u.position = i
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
  
  desc "ranks all users in each branch with any political capital"
  task :branch_users => :environment do
    for govt in Government.active.with_branches.all
      govt.switch_db    
      for branch in Branch.all
        # get the last version # for the different time lengths
        v = branch.user_rankings.find(:all, :select => "max(version) as version")[0]
        if v and v.version
          v = v.version || 0
          v+=1
        else
          v = 1
        end
        oldest = branch.user_rankings.find(:all, :select => "max(version) as version")[0].version
        v_24hr = oldest
        r = branch.user_rankings.find(:all, :select => "max(version) as version", :conditions => "created_at < date_add(now(), INTERVAL -1 DAY)")[0]
        v_24hr = r.version if r

        users = branch.users.active.by_capital.find(:all, :conditions => "capitals_count > 0 and endorsements_count > 0")
        i = 0
        for u in users
          first_time = false
          i = i + 1
          u.branch_position = i
          r = branch.user_rankings.find_by_user_id_and_version(u.id, v_24hr)
          if r # in that version
            u.branch_position_24hr = r.position
          else # didn't exist yet, so let's find the oldest one we can
            r = branch.user_rankings.find(:all, :conditions => ["user_id = ? and version < ?",u.id, v_24hr],:order => "version asc", :limit => 1)[0]
            u.branch_position_24hr = r.position if r
            u.branch_position_24hr = i unless r
          end   
          u.branch_position_24hr_change = u.branch_position_24hr - i    
      
          date = Time.now-5.hours-7.days
          c = branch.user_charts.find_by_date_year_and_date_month_and_date_day_and_user_id(date.year,date.month,date.day,u.id)
          if c
            u.branch_position_7days = c.position
            u.branch_position_7days_change = u.branch_position_7days - i   
          else
            u.branch_position_7days = 0
            u.branch_position_7days_change = 0
          end      
      
          date = Time.now-5.hours-30.days
          c = branch.user_charts.find_by_date_year_and_date_month_and_date_day_and_user_id(date.year,date.month,date.day,u.id)
          if c
            u.branch_position_30days = c.position
            u.branch_position_30days_change = u.branch_position_30days - i   
          else
            u.branch_position_30days = 0
            u.branch_position_30days_change = 0
          end      
          u.save_with_validation(false)
          r = branch.user_rankings.create(:version => v, :user => u, :position => i, :capitals_count => u.capitals_count)
        end
      end
    end
  end  
  
  desc "ditches anything older in the rankings/user_rankings tables than 8 days"
  task :thinner => :environment do
    for govt in Government.active.all
      govt.switch_db    
      Ranking.connection.execute("delete from rankings where created_at < date_add(now(), INTERVAL -8 DAY)")
      UserRanking.connection.execute("delete from user_rankings where created_at < date_add(now(), INTERVAL -8 DAY)")
      if govt.is_branches?
        BranchEndorsementRanking.connection.execute("delete from branch_endorsement_rankings where created_at < date_add(now(), INTERVAL -8 DAY)")
        BranchUserRanking.connection.execute("delete from branch_user_rankings where created_at < date_add(now(), INTERVAL -8 DAY)")
      end
    end
  end
  
end