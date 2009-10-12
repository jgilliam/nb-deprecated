class UserRanker
  
  def perform
    Government.current = Government.all.last
    
    if Government.current.is_branches?
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

    Delayed::Job.enqueue UserRanker.new, -1, 51.minutes.from_now
    
  end
 
end