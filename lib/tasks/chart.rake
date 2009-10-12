namespace :chart do  
  
  desc "priority daily update"
  task :priorities => :environment do
    Government.current = Government.all.last
    date = Time.now-4.hours-1.day
    previous_date = date-1.day
    start_date = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
    end_date = (date+1.day).year.to_s + "-" + (date+1.day).month.to_s + "-" + (date+1.day).day.to_s
    priorities = Priority.published.find(:all)
    for p in priorities
      # find the ranking
      r = p.rankings.find(:all, :conditions => ["rankings.created_at between ? and ?",start_date,end_date], :order => "created_at desc",:limit => 1)
      if r.any?
        c = p.charts.find_by_date_year_and_date_month_and_date_day(date.year,date.month,date.day)
        if not c
          c = PriorityChart.new(:priority => p, :date_year => date.year, :date_month => date.month, :date_day => date.day)
        end
        c.position = r[0].position
        c.up_count = p.endorsements.active.endorsing.count(:conditions => ["endorsements.created_at between ? and ?",start_date,end_date])
        c.down_count = p.endorsements.active.opposing.count(:conditions => ["endorsements.created_at between ? and ?",start_date,end_date])
        c.volume_count = c.up_count + c.down_count
        previous = p.charts.find_by_date_year_and_date_month_and_date_day(previous_date.year,previous_date.month,previous_date.day) 
        if previous
          c.change = previous.position-c.position
          c.change_percent = (c.change.to_f/previous.position.to_f)          
        end
        c.save
        if p.created_at+2.days > Time.now # within last two days, check to see if we've given them their priroity debut activity
          ActivityPriorityDebut.create(:user => p.user, :priority => p, :position => p.position) unless ActivityPriorityDebut.find_by_priority_id(p.id)
        end        
      end
      Rails.cache.delete('views/priority_chart-' + p.id.to_s)      
    end
    Rails.cache.delete('views/total_volume_chart') # reset the daily volume chart
    for u in User.active.at_least_one_endorsement.all
      u.index_24hr_change = u.index_change_percent(2)
      u.index_7days_change = u.index_change_percent(7)
      u.index_30days_change = u.index_change_percent(30)
      u.save_with_validation(false)
      u.expire_charts
    end
  end  
  
  desc "branch endorsement daily update"
  task :branch_endorsements => :environment do
    Government.current = Government.all.last    
    exit unless Government.current.is_branches?    
    for branch in Branch.all
      date = Time.now-4.hours-1.day
      previous_date = date-1.day
      start_date = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
      end_date = (date+1.day).year.to_s + "-" + (date+1.day).month.to_s + "-" + (date+1.day).day.to_s
      priorities = BranchEndorsement.all
      for p in priorities
        # find the ranking
        r = p.rankings.find(:all, :conditions => ["branch_endorsement_rankings.created_at between ? and ?",start_date,end_date], :order => "created_at desc",:limit => 1)
        if r.any?
          c = p.charts.find_by_date_year_and_date_month_and_date_day(date.year,date.month,date.day)
          if not c
            c = p.charts.new(:date_year => date.year, :date_month => date.month, :date_day => date.day)
          end
          c.position = r[0].position
          previous = p.charts.find_by_date_year_and_date_month_and_date_day(previous_date.year,previous_date.month,previous_date.day) 
          if previous
            c.change = previous.position-c.position
            c.change_percent = (c.change.to_f/previous.position.to_f)          
          end
          c.save
        end
        Rails.cache.delete('views/priority_chart-' + p.id.to_s)      
      end
      Rails.cache.delete('views/total_volume_chart') # reset the daily volume chart
    end
  end  
  
  desc "priority past update"
  task :past_priorities => :environment do
    Government.current = Government.all.last    
    priorities = Priority.published.find(:all)
    for p in priorities
      date = p.created_at-4.hours-1.day
      previous = nil
      while date < Time.now
        date = date+1.day
        start_date = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
        end_date = (date+1.day).year.to_s + "-" + (date+1.day).month.to_s + "-" + (date+1.day).day.to_s
        # find the ranking
        r = p.rankings.find(:all, :conditions => ["rankings.created_at between ? and ?",start_date,end_date], :order => "created_at desc",:limit => 1)
        if r.any?
          c = p.charts.find_by_date_year_and_date_month_and_date_day(date.year,date.month,date.day)
          if not c
            c = PriorityChart.new(:priority => p, :date_year => date.year, :date_month => date.month, :date_day => date.day)
          end
          c.position = r[0].position
          c.up_count = p.endorsements.active.endorsing.count(:conditions => ["endorsements.created_at between ? and ?",start_date,end_date])
          c.down_count = p.endorsements.active.opposing.count(:conditions => ["endorsements.created_at between ? and ?",start_date,end_date])
          c.volume_count = c.up_count + c.down_count
          if previous
            c.change = previous.position-c.position
            c.change_percent = (c.change.to_f/previous.position.to_f)            
          end
          c.save
          previous = c
        end
      end
      Rails.cache.delete('views/priority_chart-' + p.id.to_s)  
    end
  end  
  
  desc "priority past change update"
  task :past_priority_changes => :environment do
    Government.current = Government.all.last    
    charts = PriorityChart.find(:all, :order => "priority_id")
    current = 0
    for chart in charts
      if current != chart.priority_id
        current = chart.priority_id
        previous = nil
      end
      if previous
        chart.change = previous.position-chart.position
        chart.change_percent = (chart.change.to_f/previous.position.to_f)
        chart.save_with_validation(false)
      end
      previous = chart
    end
  end
  
  desc "user past update"
  task :past_users => :environment do
    Government.current = Government.all.last    
    users = User.active.at_least_one_endorsement.by_ranking.all
    for p in users
      date = p.created_at-4.hours-1.day
      while date < Time.now
        date = date+1.day
        start_date = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
        end_date = (date+1.day).year.to_s + "-" + (date+1.day).month.to_s + "-" + (date+1.day).day.to_s
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
        end
      end
      puts p.login
    end
  end      
  
  desc "daily user update"
  task :users => :environment do
    Government.current = Government.all.last    
    date = Time.now-4.hours-1.day
    start_date = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
    end_date = (date+1.day).year.to_s + "-" + (date+1.day).month.to_s + "-" + (date+1.day).day.to_s
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
  
  desc "daily user update for branches"
  task :branch_users => :environment do
    Government.current = Government.all.last
    exit unless Government.current.is_branches?
    for branch in Branch.all
      date = Time.now-4.hours-1.day
      start_date = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
      end_date = (date+1.day).year.to_s + "-" + (date+1.day).month.to_s + "-" + (date+1.day).day.to_s
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