class PriorityRanker
  
  def perform
    Government.current = Government.all.last

    if Government.current.is_tags? and Tag.count > 0
      # update the # of issues people who've logged in the last two hours have up endorsed
      users = User.find_by_sql("SELECT users.id, users.up_issues_count, count(distinct taggings.tag_id) as num_issues
      FROM taggings,endorsements, users
      where taggings.taggable_id = endorsements.priority_id
      and taggings.taggable_type = 'Priority'
      and endorsements.user_id = users.id
      and endorsements.value > 0
      and endorsements.status = 'active'
      and (users.loggedin_at > '#{Time.now-2.hours}' or users.created_at > '#{Time.now-2.hours}')
      group by endorsements.user_id, users.id, users.up_issues_count")
      for u in users
        u.update_attribute("up_issues_count",u.num_issues) unless u.up_issues_count == u.num_issues
      end
      # update the # of issues they've DOWN endorsed
      users = User.find_by_sql("SELECT users.id, users.down_issues_count, count(distinct taggings.tag_id) as num_issues
      FROM taggings,endorsements, users
      where taggings.taggable_id = endorsements.priority_id
      and taggings.taggable_type = 'Priority'
      and endorsements.user_id = users.id
      and endorsements.value < 0
      and endorsements.status = 'active'
      and (users.loggedin_at > '#{Time.now-2.hours}' or users.created_at > '#{Time.now-2.hours}')
      group by endorsements.user_id, users.id, users.down_issues_count")
      for u in users
        u.update_attribute("down_issues_count",u.num_issues) unless u.down_issues_count == u.num_issues
      end
    end

    # update the user's vote factor score
    users = User.active.all
    for u in users
      new_score = u.calculate_score
      if (u.score*100).to_i != (new_score*100).to_i
        u.update_attribute(:score,new_score) 
        for e in u.endorsements.active # their score changed, so now update all their endorsement scores
          current_score = e.score
          new_score = e.calculate_score
          e.update_attribute(:score, new_score) if new_score != current_score
        end
      end
    end

    # ranks all the branch endorsements, if the government uses branches
    if Government.current.is_branches?

      Government.current.update_user_default_branch
      # make sure the scores for all the positions above the max position are set to 0
      Endorsement.update_all("score = 0", "position > #{Endorsement.max_position}")
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
        r = branch.endorsement_rankings.find(:all, :select => "max(version) as version", :conditions => "branch_endorsement_rankings.created_at < '#{Time.now-1.hour}'")[0]
        v_1hr = r.version if r
        r = branch.endorsement_rankings.find(:all, :select => "max(version) as version", :conditions => "branch_endorsement_rankings.created_at < '#{Time.now-1.hour}'")[0]
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

    # ranks all the priorities in the database with any endorsements.

    # make sure the scores for all the positions above the max position are set to 0
    Endorsement.update_all("score = 0", "position > #{Endorsement.max_position}")      
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
    r = Ranking.find(:all, :select => "max(version) as version", :conditions => "created_at < '#{Time.now-1.hour}'")[0]
    v_1hr = r.version if r
    r = Ranking.find(:all, :select => "max(version) as version", :conditions => "created_at < '#{Time.now-1.hour}'")[0]
    v_24hr = r.version if r

    if Government.current.is_branches?
      priorities = Priority.find_by_sql("
         select priorities.id, priorities.endorsements_count, branch_endorsements.priority_id, sum(branches.rank_factor*branch_endorsements.score) as number 
         from priorities, branch_endorsements, branches
         where branch_endorsements.branch_id = branches.id and branch_endorsements.priority_id = priorities.id
         and priorities.status = 'published'
         group by priorities.id, priorities.endorsements_count, branch_endorsements.priority_id
         order by number desc")
    else
      priorities = Priority.find_by_sql("
         select priorities.id, priorities.endorsements_count, sum(((#{Endorsement.max_position+1}-endorsements.position)*endorsements.value)*users.score) as number
         from users,endorsements,priorities
         where endorsements.user_id = users.id
         and endorsements.priority_id = priorities.id
         and priorities.status = 'published'
         and endorsements.status = 'active' and endorsements.position <= #{Endorsement.max_position}
         group by priorities.id, priorities.endorsements_count, endorsements.priority_id
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

   
    # determines any changes in the #1 priority for an issue, and updates the # of distinct endorsers and opposers across the entire issue
    
    if Government.current.is_tags? and Tag.count > 0
      keep = []
      # get the number of endorsers on the issue
      tags = Tag.find_by_sql("SELECT tags.id, tags.name, tags.top_priority_id, tags.controversial_priority_id, tags.rising_priority_id, tags.obama_priority_id, count(distinct endorsements.user_id) as num_endorsers
      FROM tags,taggings,endorsements
      where 
      taggings.taggable_id = endorsements.priority_id
      and taggable_type = 'Priority'
      and taggings.tag_id = tags.id
      and endorsements.status = 'active'
      and endorsements.value > 0
      group by tags.id, tags.name, tags.top_priority_id, tags.controversial_priority_id, tags.rising_priority_id, tags.obama_priority_id, taggings.tag_id")
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
       end
       tag.up_endorsers_count = tag.num_endorsers
       tag.save_with_validation(false)
      end
      # get the number of opposers on the issue
      tags = Tag.find_by_sql("SELECT tags.id, tags.name, tags.down_endorsers_count, count(distinct endorsements.user_id) as num_opposers
      FROM tags,taggings,endorsements
      where 
      taggings.taggable_id = endorsements.priority_id
      and taggable_type = 'Priority'
      and taggings.tag_id = tags.id
      and endorsements.status = 'active'
      and endorsements.value < 0
      group by tags.id, tags.name, tags.down_endorsers_count, taggings.tag_id")    
      for tag in tags
       keep << tag.id
       tag.update_attribute(:down_endorsers_count,tag.num_opposers) unless tag.down_endorsers_count == tag.num_opposers
      end
      if keep.any?
       Tag.connection.execute("update tags set up_endorsers_count = 0, down_endorsers_count = 0 where id not in (#{keep.uniq.compact.join(',')})")
      end
    end
    
    Delayed::Job.enqueue PriorityRanker.new, -1, 47.minutes.from_now
    
  end
 
end