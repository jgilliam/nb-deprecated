class PrioritizerController < ApplicationController

  before_filter :login_required

  def index
    @page_title = t('prioritizer.index.title', :government_name => current_government.name)
    n = choose_next
    respond_to do |format|
      format.html {render :template => "prioritizer/" + n}
    end    
  end
  
  def winner1
    load_endorsements
    @endorsement1.insert_at(@endorsement2.position)
    if @endorsement1.is_down?
      msg = t('prioritizer.oppose.moved.msg',:priority_name => @endorsement1.priority.name, :position => @endorsement1.position)    
    else
      msg = t('prioritizer.endorse.moved.msg',:priority_name => @endorsement1.priority.name, :position => @endorsement1.position)    
    end
    n = choose_next
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "quiz_changes", '<div id="prioritizer_changes">' + msg + '</div>'
          page.replace_html "quiz", :partial => "prioritizer/" + n
          page.replace_html 'your_priorities_container', :partial => "priorities/yours"
          page.visual_effect :highlight, 'your_priorities'          
          page.visual_effect :drop_out, "prioritizer_changes", :duration => 4
        end
      }
    end
  end
  
  def same
    load_endorsements
    diff = ((@endorsement1.position-@endorsement2.position)/2).to_i
    @endorsement1.insert_at(@endorsement1.position-diff)
    @endorsement2.insert_at(@endorsement2.position+diff)
    msg = t('prioritizer.same.msg', :position => @endorsement2.position, :position2 => @endorsement1.position)
    n = choose_next
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "quiz_changes", '<div id="prioritizer_changes">' + msg + '</div>'
          page.replace_html "quiz", :partial => "prioritizer/" + n
          page.replace_html 'your_priorities_container', :partial => "priorities/yours"
          page.visual_effect :highlight, 'your_priorities'          
          page.visual_effect :drop_out, "prioritizer_changes", :duration => 4
        end
      }
    end
  end  
  
  def winner2
    n = choose_next
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "quiz", :partial => "prioritizer/" + n
        end
      }
    end 
  end
  
  def endorse
    @value = (params[:value]||1).to_i
    @priority = Priority.find(params[:id])
    if @value == 1
      @endorsement = @priority.endorse(current_user,request,current_partner,@referral)
      msg = t('prioritizer.endorse.msg',:priority_name => @priority.name, :position => @endorsement.position)
    else
      @endorsement = @priority.oppose(current_user,request,current_partner,@referral)
      msg = t('prioritizer.oppose.msg',:priority_name => @priority.name, :position => @endorsement.position)
    end
    if current_user.endorsements_count > 24
      session[:endorsement_page] = (@endorsement.position/25).to_i+1
      session[:endorsement_page] -= 1 if @endorsement.position == (session[:endorsement_page]*25)-25
    end
    n = choose_next
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "quiz_changes", '<div id="prioritizer_changes">' + msg + '</div>'
          page.replace_html "quiz", :partial => "prioritizer/" + n
          page.replace_html 'your_priorities_container', :partial => "priorities/yours"
          page.visual_effect :highlight, 'your_priorities'
          page.visual_effect :drop_out, "prioritizer_changes", :duration => 4
        end
      }
    end
  end  

  def skip
    n = choose_next
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "quiz", :partial => "prioritizer/" + n
        end
      }
    end
  end

  private
  
    def load_endorsements
      @endorsement1 = current_user.endorsements.find(params[:endorsement1])
      @endorsement2 = current_user.endorsements.find(params[:endorsement2])
    end
  
    def new_duel
      @endorsement1 = current_user.endorsements.active.find(:all, :conditions => "position > 5", :order => "rand()", :limit => 1)[0]
      @endorsement2 = current_user.endorsements.active.find(:all, :conditions => "position between #{(@endorsement1.position/1.5).to_i-2} and #{(@endorsement1.position/1.5).to_i+2} and id <> #{@endorsement1.id.to_s}", :order => "rand()", :limit => 1)[0]
    end
    
    def new_single
      if current_user.endorsements_count > 3
        @priority = Priority.published.find(:all, :conditions => ["id not in (?)",current_priority_ids], :order => "rand()", :limit => 1)[0]
      else
        @priority = Priority.published.find(:all, :conditions => ["position <= ?",Endorsement.max_position], :order => "rand()", :limit => 1)[0]
      end
    end
    
    def choose_next
      if Time.now.to_i.odd? or current_user.endorsements_count < 5
        new_single
        return "single"
      else
        new_duel
        return "duel"
      end
    end

end
