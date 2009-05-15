class BriefingController < ApplicationController

  def index
    redirect_to newest_points_url
  end
  
end
