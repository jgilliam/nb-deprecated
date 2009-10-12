namespace :rank do  
  
  desc "ditches anything older in the rankings/user_rankings tables than 8 days"
  task :thinner => :environment do
    Government.current = Government.all.last    
    Ranking.connection.execute("delete from rankings where created_at < date_add(now(), INTERVAL -8 DAY)")
    UserRanking.connection.execute("delete from user_rankings where created_at < date_add(now(), INTERVAL -8 DAY)")
    if Government.current.is_branches?
      BranchEndorsementRanking.connection.execute("delete from branch_endorsement_rankings where created_at < date_add(now(), INTERVAL -8 DAY)")
      BranchUserRanking.connection.execute("delete from branch_user_rankings where created_at < date_add(now(), INTERVAL -8 DAY)")
    end
  end
  
end