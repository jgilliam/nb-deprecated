class ProcessFinishedMergeProposals
  
  def perform
    Government.current = Government.all.last    
    changes = Change.find(:all, :conditions => "changes.status = 'sent'", :include => :priority)
    for change in changes
      if change.priority.endorsements_count == 0 # everyone has moved out of the priority, it's alright to end it
        change.approve!
      elsif change.is_expired? and change.is_passing?
        change.approve!
      elsif change.is_expired? and change.yes_votes == 0 and change.no_votes == 0 # no one voted, go ahead and approve it
        change.approve!
      elsif change.is_expired? and change.yes_votes == change.no_votes # a tie! leave it the same
        change.decline!
      elsif change.is_expired? and change.is_failing? # more no votes, decline it
        change.decline!
      end
    end
    Delayed::Job.enqueue ProcessFinishedMergeProposals.new, -1, 20.minutes.from_now
  end

end