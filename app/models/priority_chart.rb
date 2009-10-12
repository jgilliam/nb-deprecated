class PriorityChart < ActiveRecord::Base
  
  belongs_to :priority
  
  named_scope :oldest_first, :order => "date_year asc, date_month asc, date_day asc", :limit => 90
  named_scope :newest_first, :order => "date_year desc, date_month desc, date_day desc", :limit => 90
   
  def date_show
    Time.parse(date_year.to_s + '-' + date_month.to_s + '-' + date_day.to_s).strftime("%b %d")
  end
    
  def PriorityChart.volume(limit=30)
    pc = PriorityChart.find_by_sql(["SELECT date_year, date_month, date_day, sum(priority_charts.volume_count) as volume_count
    from priority_charts
    group by date_year, date_month, date_day
    order by date_year desc, date_month desc, date_day desc
    limit ?",limit])
    pc.collect{|c| c.volume_count.to_i}.reverse
  end
    
end