class AboutController < ApplicationController
  
  def index
    @page_title = t('about.index', :government_name => current_government.name)
  end
  
  def show
    if params[:id] == 'privacy'
      @page_title = t('about.privacy', :government_name => current_government.name)       
      render :action => "privacy"
    elsif params[:id] == 'rules'
      @page_title = t('about.rules', :government_name => current_government.name)     
      render :action => "rules"
    elsif params[:id] == 'faq'
      @page_title = t('about.faq', :government_name => current_government.name)      
      render :action => "faq"
    elsif params[:id] == 'stimulus'
      @page_title = "How America rates the stimulus package"
      render :action => "stimulus"      
    elsif params[:id] == 'congress'
      redirect_to "http://hellocongress.org/"
      return
    else
      @page = Page.find_by_short_name(params[:id])
      @page_title = @page.name
    end
  end
  
end
