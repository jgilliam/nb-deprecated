class ExportController < ApplicationController

  layout false

  def stratml
    @tags = Tag.most_priorities.find(:all, :conditions => "tags.id <> 384 and priorities_count > 4")
    respond_to do |format|
      format.xml
    end
  end
  
end
