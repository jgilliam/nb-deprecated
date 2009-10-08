class DelayedJob < ActiveRecord::Base

  named_scope :by_priority, :order => "locked_by asc, priority desc, run_at asc"
  
end
