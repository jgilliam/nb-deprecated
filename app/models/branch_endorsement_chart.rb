class BranchEndorsementChart < ActiveRecord::Base

  belongs_to :branch_endorsement
  
  named_scope :oldest_first, :order => "date_year asc, date_month asc, date_day asc", :limit => 90
  named_scope :newest_first, :order => "date_year desc, date_month desc, date_day desc", :limit => 90
   
  def date_show
    Time.parse(date_year.to_s + '-' + date_month.to_s + '-' + date_day.to_s).strftime("%b %d")
  end
    
end
