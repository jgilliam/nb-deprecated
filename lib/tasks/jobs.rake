namespace :jobs do  
  
  desc "queue up always running delayed jobs"
  task :enqueue => :environment do
    Delayed::Job.enqueue ProcessFinishedMergeProposals.new, -1, 20.minutes.from_now
  end

end