class CongressIssue < ActiveRecord::Base

  use_db :prefix => "congress_"
  self.table_name = 'issues'

end
