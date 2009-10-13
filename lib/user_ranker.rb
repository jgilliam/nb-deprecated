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
        r = branch.user_rankings.find(:all, :select => "max(version) as version", :conditions => "created_at < '#{Time.now-24.hours}'")[0]
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
    r = UserRanking.find(:all, :select => "max(version) as version", :conditions => "created_at < '#{Time.now-24.hours}'")[0]
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

    # now check to see if the charts have been updated for the day
    
    date = Time.now-4.hours-1.day
    start_date = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
    end_date = (date+1.day).year.to_s + "-" + (date+1.day).month.to_s + "-" + (date+1.day).day.to_s
    
    if Government.current.is_branches?
      if BranchUserChart.count(:conditions => ["date_year = ? and date_month = ? and date_day = ?", date.year, date.month, date.day]) == 0  # check to see if it's already been done for yesterday
        for branch in Branch.all
          users = branch.users.active.at_least_one_endorsement.by_ranking.all
          for p in users
            # find the ranking
            r = branch.user_rankings.find(:all, :conditions => ["user_id = ? and branch_user_rankings.created_at between ? and ?",p.id, start_date,end_date], :order => "created_at desc",:limit => 1)
            if r.any?
              c = branch.user_charts.find_by_date_year_and_date_month_and_date_day_and_user_id(date.year,date.month,date.day,p.id)
              if not c
                c = branch.user_charts.new(:user => p, :date_year => date.year, :date_month => date.month, :date_day => date.day)
              end
              c.position = r[0].position
              c.save
            end
          end    
        end
      end
    end

    if UserChart.count(:conditions => ["date_year = ? and date_month = ? and date_day = ?", date.year, date.month, date.day]) == 0  # check to see if it's already been done for yesterday
      users = User.active.at_least_one_endorsement.by_ranking.all
      for p in users
        # find the ranking
        r = p.rankings.find(:all, :conditions => ["user_rankings.created_at between ? and ?",start_date,end_date], :order => "created_at desc",:limit => 1)
        if r.any?
          c = p.charts.find_by_date_year_and_date_month_and_date_day(date.year,date.month,date.day)
          if not c
            c = UserChart.new(:user => p, :date_year => date.year, :date_month => date.month, :date_day => date.day)
          end
          c.position = r[0].position
          up_capitals = Capital.find(:all, :conditions => ["((recipient_id = ? and amount > 0) or (sender_id = ? and amount < 0)) and created_at between ? and ?", p.id, p.id, start_date, end_date])
          c.up_count = 0
          for cap in up_capitals
            c.up_count += cap.amount.abs
          end
          down_capitals = Capital.find(:all, :conditions => ["((recipient_id = ? and amount < 0) or (sender_id = ? and amount > 0)) and created_at between ? and ?", p.id, p.id, start_date, end_date])
          c.down_count = 0
          for cap in down_capitals
            c.down_count += cap.amount.abs
          end          
          c.volume_count = c.up_count + c.down_count
          c.save
          if p.created_at+2.days > Time.now # within last two days, check to see if we've given them their priroity debut activity
            ActivityUserRankingDebut.create(:user => p, :user_chart => c) unless ActivityUserRankingDebut.find_by_user_id(p.id)
          end          
        end
      end
    end

    Delayed::Job.enqueue UserRanker.new, -1, 51.minutes.from_now
    
  end
 
end