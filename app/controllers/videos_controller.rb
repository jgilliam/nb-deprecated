class VideosController < ApplicationController
  
  def index
    redirect_to :controller => "about"
    return
  end
  
end
