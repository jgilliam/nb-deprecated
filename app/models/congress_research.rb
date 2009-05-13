class CongressResearch < ActiveRecord::Base

  use_db :prefix => "congress_"
  self.table_name = 'researches'
  
  belongs_to :issue, :class_name => "CongressIssue"
  belongs_to :legislator, :class_name => "CongressLegislator"
  
end
