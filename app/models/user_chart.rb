class UserChart < ActiveRecord::Base

  belongs_to :user
  
  named_scope :oldest_first, :order => "date_year asc, date_month asc, date_day asc"
   
  def date_show
    Time.parse(date_year.to_s + '-' + date_month.to_s + '-' + date_day.to_s).strftime("%b %d")
  end
  
end
