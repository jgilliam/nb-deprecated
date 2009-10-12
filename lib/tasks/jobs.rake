namespace :jobs do  
  
  desc "queue up always running delayed jobs"
  task :enqueue => :environment do
    Delayed::Job.enqueue PriorityRanker.new, -1, 47.minutes.from_now
    Delayed::Job.enqueue UserRanker.new, -1, 51.minutes.from_now    
    Delayed::Job.enqueue ProcessFinishedMergeProposals.new, -2, 20.minutes.from_now
    Delayed::Job.enqueue FixTopEndorsements.new, -3, 2.minutes.from_now
  end

end