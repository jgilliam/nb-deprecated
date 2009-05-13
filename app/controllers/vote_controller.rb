class VoteController < ApplicationController

  before_filter :get_vote, :except => :index
  
  def index
    redirect_to "/"
  end
  
  def yes
    @vote.approve!
    flash[:notice] = t('vote.approve', :priority_name => @vote.change.new_priority.name)
    self.current_user = @vote.user unless logged_in?
    redirect_to priority_change_url(@vote.change.priority, @vote.change)
    return
  end
  
  def maybe
    self.current_user = @vote.user unless logged_in?
    redirect_to priority_change_url(@vote.change.priority, @vote.change)
    return
  end  
  
  def no
    @vote.decline!
    flash[:notice] = t('vote.decline', :priority_name => @vote.change.priority.name)
    self.current_user = @vote.user unless logged_in?
    redirect_to priority_change_url(@vote.change.priority, @vote.change)
    return
  end

  private
  def get_vote
    @vote = Vote.find_by_code(params[:code])
    if not @vote
      flash[:error] = t('vote.error')
    end
    for n in @vote.notifications.unread
      n.read!
    end
    if @vote.status == 'approved'
      flash[:error] = t('vote.already_voted_yes', :priority_name => @vote.change.new_priority.name)
      redirect_to @vote.change.new_priority
      return
    elsif @vote.status == 'declined'
      flash[:error] = t('vote.already_voted_no', :priority_name => @vote.change.priority.name)
      redirect_to @vote.change.priority      
      return
    elsif @vote.status == 'implicit_approved'
      flash[:error] = t('vote.implicit_approved', :priority_name => @vote.change.new_priority.name)
      redirect_to @vote.change.new_priority
      return      
    elsif @vote.status == 'implicit_declined'
      flash[:error] = t('vote.implicit_declined', :priority_name => @vote.change.priority.name)
      redirect_to @vote.change.priority      
      return      
    elsif @vote.status == 'inactive'
      flash[:error] = t('vote.inactive')
      if @vote.change.status == 'approved'
        redirect_to @vote.change.new_priority
      else
        redirect_to @vote.change.priority
      end
      return
    elsif @vote.status == 'deleted'
      redirect_to "/"
      return
    end    
    
  end
  
end
