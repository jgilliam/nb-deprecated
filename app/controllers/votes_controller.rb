class VotesController < ApplicationController
  
  before_filter :get_priority
  before_filter :login_required
  before_filter :admin_required, :only => [:edit, :update, :destroy]
  
  def get_priority
    @priority = Priority.find(params[:priority_id])
    @change = @priority.change.find(params[:change_id])
  end  
  
  # GET /priorities/1/changes/3/votes
  # GET /priorities/1/changes/3/votes.xml
  def index
    @votes = @change.votes.find(:all)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /priorities/1/changes/3/votes/1
  # GET /priorities/1/changes/3/votes/1.xml
  def show
    @vote = @change.votes.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /priorities/1/changes/3/votes/new
  # GET /priorities/1/changes/3/votes/new.xml
  def new
    @vote = @change.votes.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /priorities/1/changes/3/votes/1/edit
  def edit
    @vote = @change.votes.find(params[:id])
  end

  # POST /priorities/1/changes/3/votes
  # POST /priorities/1/changes/3/votes.xml
  def create
    @vote = @change.votes.new(params[:vote])

    respond_to do |format|
      if @vote.save
        flash[:notice] = t('votes.new.success')
        format.html { priority_change_vote(@priority,@change,@vote) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /priorities/1/changes/3/votes/1
  # PUT /priorities/1/changes/3/votes/1.xml
  def update
    @vote = @change.votes.find(params[:id])

    respond_to do |format|
      if @vote.update_attributes(params[:vote])
        flash[:notice] = t('votes.new.success')
        format.html { priority_change_vote(@priority,@change,@vote) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /priorities/1/changes/3/votes/1
  # DELETE /priorities/1/changes/3/votes/1.xml
  def destroy
    @vote = @change.votes.find(params[:id])
    @vote.destroy

    respond_to do |format|
      format.html { redirect_to(votes_url) }
    end
  end
end
