class FixTopEndorsements
  
  # i really have to figure out this bug so this doesn't have to run all the time.
  
  def perform
    Government.current = Government.all.last    
    for u in User.find_by_sql("select * from users where top_endorsement_id not in (select id from endorsements)")
      u.top_endorsement = u.endorsements.active.by_position.find(:all, :limit => 1)[0]
      u.save_with_validation(false)        
      puts u.login
    end
    Delayed::Job.enqueue FixTopEndorsements.new, -3, 2.minutes.from_now
  end

end