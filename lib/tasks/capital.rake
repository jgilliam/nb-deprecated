namespace :capital do  
  
  # loops through the point qualities to see if anyone deserves some political capital
  desc "helpful / unhelpful talking points & documents"
  task :helpful_add => :environment do
    Government.current = Government.all.last    
    points = Point.published.find(:all, :include => :user)
    for point in points
      point.calculate_score
      point.save_with_validation(false)
      next if not point.user.is_active?
      endorsement = Endorsement.find_by_user_id_and_priority_id(point.user_id, point.priority_id)
      if point.opposer_score > 1 and point.helpful_opposers_capital_spent < 1
        # give capital for a talking point helpful to opposers
        point.capitals << CapitalPointHelpfulOpposers.new(:recipient => point.user, :amount => 1)  
      end      
      if point.endorser_score > 1 and point.helpful_endorsers_capital_spent < 1
        # give capital for a talking point helpful to endorsers
        point.capitals << CapitalPointHelpfulEndorsers.new(:recipient => point.user, :amount => 1)
      end
      if point.neutral_score > 1 and point.helpful_undeclareds_capital_spent < 1
        # give capital for a talking point helpful to undeclareds
        point.capitals << CapitalPointHelpfulUndeclareds.new(:recipient => point.user, :amount => 1)
      end        
      if point.endorser_score < -0.5 and endorsement and endorsement.is_up? and point.helpful_endorsers_capital_spent >= 0
        # charge an endorser for a talking point that endorsers found unhelpful
        point.capitals << CapitalPointHelpfulEndorsers.new(:recipient => point.user, :amount => -1)
      end
      if point.opposer_score < -0.5 and endorsement and endorsement.is_down? and point.helpful_opposers_capital_spent >= 0
        # charge an opposer for a talking point that opposers found unhelpful
        point.capitals << CapitalPointHelpfulOpposers.new(:recipient => point.user, :amount => -1)
      end
      if point.neutral_score < -0.5 and not endorsement and point.helpful_undeclareds_capital_spent >= 0
        # charge an undeclared for a talking point that undeclareds found unhelpful
        point.capitals << CapitalPointHelpfulUndeclareds.new(:recipient => point.user, :amount => -1)
      end        
      if point.opposer_score > 1 and point.endorser_score > 1 and point.helpful_everyone_capital_spent < 1
        # give capital for a talking point that both opposers and endorsers found helpful
        point.capitals << CapitalPointHelpfulEveryone.new(:recipient => point.user, :amount => 1)
      end      
      if point.opposer_score < -0.5 and point.endorser_score < -0.5 and point.helpful_everyone_capital_spent >= 0
        # charge for a talking point that both opposers and endorsers found unhelpful
        point.capitals << CapitalPointHelpfulEveryone.new(:recipient => point.user, :amount => -1)        
      end
    end
    documents = Document.published.find(:all, :conditions => "priority_id is not null", :include => :user)
    for document in documents
      document.calculate_score
      document.save_with_validation(false)     
      next if not document.user.is_active?   
      endorsement = Endorsement.find_by_user_id_and_priority_id(document.user_id, document.priority_id)
      if document.opposer_score > 1 and document.helpful_opposers_capital_spent < 1
        # give capital for a document helpful to opposers
        document.capitals << CapitalDocumentHelpfulOpposers.new(:recipient => document.user, :amount => 1)  
      end      
      if document.endorser_score > 1 and document.helpful_endorsers_capital_spent < 1
        # give capital for a document helpful to endorsers
        document.capitals << CapitalDocumentHelpfulEndorsers.new(:recipient => document.user, :amount => 1)
      end
      if document.neutral_score > 1 and document.helpful_undeclareds_capital_spent < 1
        # give capital for a document helpful to undeclareds
        document.capitals << CapitalDocumentHelpfulUndeclareds.new(:recipient => document.user, :amount => 1)
      end        
      if document.endorser_score < -0.5 and endorsement and endorsement.is_up? and document.helpful_endorsers_capital_spent >= 0
        # charge an endorser for a document that endorsers found unhelpful
        document.capitals << CapitalDocumentHelpfulEndorsers.new(:recipient => document.user, :amount => -1)
      end
      if document.opposer_score < -0.5 and endorsement and endorsement.is_down? and document.helpful_opposers_capital_spent >= 0
        # charge an opposer for a document that opposers found unhelpful
        document.capitals << CapitalDocumentHelpfulOpposers.new(:recipient => document.user, :amount => -1)
      end
      if document.neutral_score < -0.5 and not endorsement and document.helpful_undeclareds_capital_spent >= 0
        # charge an undeclared for a document that undeclareds found unhelpful
        document.capitals << CapitalDocumentHelpfulUndeclareds.new(:recipient => document.user, :amount => -1)
      end        
      if document.opposer_score > 1 and document.endorser_score > 1 and document.helpful_everyone_capital_spent < 1
        # give capital for a document that both opposers and endorsers found helpful
        document.capitals << CapitalDocumentHelpfulEveryone.new(:recipient => document.user, :amount => 1)
      end      
      if document.opposer_score < -0.5 and document.endorser_score < -0.5 and document.helpful_everyone_capital_spent >= 0
        # charge for a document that both opposers and endorsers found unhelpful
        document.capitals << CapitalDocumentHelpfulEveryone.new(:recipient => document.user, :amount => -1)        
      end   
    end
  end
  
end