class EndorsementsController < ApplicationController
 
  before_filter :login_required, :except => :index
  
  # GET /endorsements
  # GET /endorsements.xml
  def index
    @endorsements = Endorsement.active_and_inactive.by_recently_created(:include => [:user,:priority]).paginate :page => params[:page]
    respond_to do |format|
      format.html { redirect_to yours_priorities_url }
      format.xml { render :xml => @endorsements.to_xml(:include => [:user, :priority], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:user, :priority], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def edit
    @endorsement = current_user.endorsements.find(params[:id])
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'priority_left'
            page.replace_html 'priority_' + @endorsement.priority.id.to_s + '_position', render(:partial => "endorsements/position_form", :locals => {:endorsement => @endorsement})
            page['endorsement_' + @endorsement.id.to_s + "_position_edit"].focus
          elsif params[:region] == 'yours'
            page.replace_html 'endorsement_' + @endorsement.id.to_s, render(:partial => "endorsements/row_form", :locals => {:endorsement => @endorsement})
            page['endorsement_' + @endorsement.id.to_s + "_row_edit"].focus
          end
        end        
      }
    end
  end
  
  def update
    @endorsement = current_user.endorsements.find(params[:id])
    return if params[:endorsement][:position].to_i < 1  # if they didn't put a number in, don't do anything
    if @endorsement.insert_at(params[:endorsement][:position]) 
      respond_to do |format|
        format.js {
          render :update do |page|
            if params[:region] == 'priority_left'
              page.replace_html 'priority_' + @endorsement.priority.id.to_s + "_position",render(:partial => "endorsements/position", :locals => {:endorsement => @endorsement})
            elsif params[:region] == 'yours'
            end
            page.replace_html 'your_priorities_container', :partial => "priorities/yours"              
          end        
        }
      end
    end
  end
  
  # DELETE /endorsements/1
  def destroy
    if current_user.is_admin?
      @endorsement = Endorsement.find(params[:id])
    else
      @endorsement = current_user.endorsements.find(params[:id])
    end
    return unless @endorsement
    @priority = @endorsement.priority
    eid = @endorsement.id
    @endorsement.destroy
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'priority_left'
            page.replace_html 'priority_' + @priority.id.to_s + "_button",render(:partial => "priorities/button", :locals => {:priority => @priority, :endorsement => nil})
            page.replace_html 'priority_' + @priority.id.to_s + "_position",render(:partial => "endorsements/position", :locals => {:endorsement => nil})
            page.replace 'endorser_link', render(:partial => "priorities/endorser_link") 
            page.replace 'opposer_link', render(:partial => "priorities/opposer_link")             
            if @endorsement.is_up?
              @activity = ActivityEndorsementDelete.find_by_priority_id_and_user_id(@priority.id,current_user.id, :order => "created_at desc")
            else
              @activity = ActivityOppositionDelete.find_by_priority_id_and_user_id(@priority.id,current_user.id, :order => "created_at desc")
            end          
            page.insert_html :top, 'activities', render(:partial => "activities/show", :locals => {:activity => @activity, :suffix => "_noself"})
            page.replace_html 'your_priorities_container', :partial => "priorities/yours"
            page.visual_effect :highlight, 'your_priorities'            
          elsif params[:region] == 'priority_inline'
            page.select('#priority_' + @priority.id.to_s + "_endorsement_count").each { |item| item.replace(render(:partial => "priorities/endorsement_count", :locals => {:priority => @priority})) }
            page.select('#priority_' + @priority.id.to_s + "_button_small").each {|item| item.replace(render(:partial => "priorities/button_small", :locals => {:priority => @priority, :endorsement => nil}))}
            page.replace_html 'your_priorities_container', :partial => "priorities/yours"
            page.visual_effect :highlight, 'your_priorities'            
          elsif params[:region] == 'your_priorities'
            page.visual_effect :fade, 'endorsement_' + eid.to_s, :duration => 0.5
            page.replace_html 'your_priorities_container', :partial => "priorities/yours"
          elsif params[:region] == 'ad'
            page.replace_html 'your_priorities_container', :partial => "priorities/yours"
            page.visual_effect :highlight, 'your_priorities'                        
          end     
        end
      }    
    end
  end

end
