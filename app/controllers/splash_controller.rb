class SplashController < ApplicationController

  def index
    @page_title = t('splash.index.title', :government_name => current_government.name)
    if User.adapter == 'postgresql'
      @priorities = Priority.find :all, :conditions => "status='published' and position > 0 and endorsements_count > 2", :order => "RANDOM()", :limit => 200
    else
      @priorities = Priority.find :all, :conditions => "status='published' and position > 0 and endorsements_count > 2", :order => "rand()", :limit => 200
    end
  end  
  
end
