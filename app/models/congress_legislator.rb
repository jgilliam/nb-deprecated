class CongressLegislator < ActiveRecord::Base

  use_db :prefix => "congress_"
  self.table_name = 'legislators'

end
