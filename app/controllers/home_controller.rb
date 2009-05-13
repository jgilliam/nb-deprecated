class HomeController < ApplicationController
  
  def top_issues
    @issues = Tag.most_priorities.all(:include => :top_priority, :limit => 10)
  end  
  
end
