task :cron => :environment do

  Government.current = Government.all.last    

  # crawls through everyone's account and makes sure their endorsement positions are accurate
  for u in User.active.at_least_one_endorsement.all(:order => "users.id asc")
    row = 0
    changed = false
    for e in u.endorsements.active.by_position
      row += 1
      if e.position != row
        e.update_attribute(:position,row) 
        changed = true
      end
      if u.top_endorsement_id != e.id and row == 1
        changed = true
        u.update_attribute(:top_endorsement_id,e.id) 
      end
    end
    if changed
      # updates their counts
      u.update_counts
      u.save_with_validation(false)
      puts "updated endorsement positions of " + u.login
    end
  end

  # update the user counts for all users who logged in during the last 25 hours, just to make sure they're right
  for u in User.find(:all, :conditions => "loggedin_at > '#{Time.now-25.hours}'")
    u.update_counts
    u.save_with_validation(false)
    puts "updated counts of " + u.login
  end

  # thin out the rankings and user rankings table, deleting everything older than 8 days
  Ranking.connection.execute("delete from rankings where created_at < '#{Time.now-8.days}'")
  UserRanking.connection.execute("delete from user_rankings where created_at < '#{Time.now-8.days}'")
  if Government.current.is_branches?
    BranchEndorsementRanking.connection.execute("delete from branch_endorsement_rankings where created_at < '#{Time.now-8.days}'")
    BranchUserRanking.connection.execute("delete from branch_user_rankings where created_at < '#{Time.now-8.days}'")
  end
  puts "thinned out old rankings"

  # follow all the new followers for twitter users
  users = User.authorized_twitterers.active.by_twitter_crawled_at
  for user in users
    Delayed::Job.enqueue LoadTwitterFollowers.new(user.id), -2
  end

  if Time.now.wday == 6 # if it's saturday
    
    # deduct capital for people who haven't logged in recently
    users = User.active.no_recent_login.find(:all, :conditions => "capitals_count > 3")
    for user in users
      capital_lost = -((((Time.now-user.loggedin_at)/86400)/30).round/2)
      capital_to_deduct = capital_lost.round - user.inactivity_capital_lost
      if capital_to_deduct < 0
        ActivityCapitalInactive.create(:user => user, :capital => CapitalInactive.create(:recipient => user, :amount => capital_to_deduct))
        puts "deducted " + capital_to_deduct.to_s + "pc from " + user.login + " for not logging in recently"
      end
    end
    
    # update related priorities
    
    priorities = Priority.published.tagged.top_rank.all
    for priority in priorities
      time_started = Time.now
      keep = []
      for p in priority.endorsers_endorsed(5)
        pct = (p.percentage.to_f*100).to_i
        next unless pct > 19
        rel = RelationshipEndorserEndorsed.find_by_priority_id_and_other_priority_id(priority.id,p.id)
        if rel
          rel.update_attribute("percentage",pct) unless rel.percentage == pct
        else
          rel = RelationshipEndorserEndorsed.create(:priority => priority, :other_priority => p, :percentage => pct)
        end
        keep << rel.id
      end
      for p in priority.undecideds_endorsed(5)
        pct = (p.percentage.to_f*100).to_i
        next unless pct > 19        
        rel = RelationshipUndecidedEndorsed.find_by_priority_id_and_other_priority_id(priority.id,p.id)
        if rel
          rel.update_attribute("percentage",pct) unless rel.percentage == pct
        else
          rel = RelationshipUndecidedEndorsed.create(:priority => priority, :other_priority => p, :percentage => pct)
        end
        keep << rel.id
      end
      for p in priority.opposers_endorsed(5)
        pct = (p.percentage.to_f*100).to_i
        next unless pct > 19        
        rel = RelationshipOpposerEndorsed.find_by_priority_id_and_other_priority_id(priority.id,p.id)
        if rel
          rel.update_attribute("percentage",pct) unless rel.percentage == pct
        else
          rel = RelationshipOpposerEndorsed.create(:priority => priority, :other_priority => p, :percentage => pct)
        end
        keep << rel.id
      end
      old_rels = Relationship.who_endorsed.find(:all, :conditions => ["id not in (?) and priority_id = ?",keep,priority.id])
      for rel in old_rels
        rel.destroy
      end
      puts 'updated related priorities ' + priority.name + ' ' + (Time.now-time_started).seconds.to_s
    end
    
  end

end