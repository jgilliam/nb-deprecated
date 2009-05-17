namespace :maint do  
  
  desc "process merge proposals"
  task :merge_proposals => :environment do
    for govt in Government.active.all
      govt.switch_db    
      changes = Change.find(:all, :conditions => "changes.status = 'sent'", :include => :priority)
      for change in changes
        if change.priority.endorsements_count == 0 # everyone has moved out of the priority, it's alright to end it
          change.approve!
        elsif change.is_expired? and change.is_passing?
          change.approve!
        elsif change.is_expired? and change.yes_votes == 0 and change.no_votes == 0 # no one voted, go ahead and approve it
          change.approve!
        elsif change.is_expired? and change.yes_votes == change.no_votes # a tie! leave it the same
          change.decline!
        elsif change.is_expired? and change.is_failing? # more no votes, decline it
          change.decline!
        end
      end
    end
  end
  
  desc "process notifications and send invitations"
  task :process_notifications => :environment do
    for govt in Government.active.all
      govt.switch_db    
      for n in Notification.unread.unprocessed.all  # this won't send anything if they've already seen the notification, ie, if they are actively on the site using it.
        n.send!
      end
      for contact in UserContact.tosend.all
        contact.send!
      end      
    end
  end  
  
  desc "fix endorsement counts"
  task :fix_endorsement_counts => :environment do
    for govt in Government.active.all
      govt.switch_db    
      for p in Priority.find(:all)
        p.endorsements_count = p.endorsements.active_and_inactive.size
        p.up_endorsements_count = p.endorsements.endorsing.active_and_inactive.size
        p.down_endorsements_count = p.endorsements.opposing.active_and_inactive.size
        p.save_with_validation(false)      
      end
    end
  end
  
  desc "fix endorsement positions"
  task :fix_endorsement_positions => :environment do
    for govt in Government.active.all
      govt.switch_db    
      for u in User.active.at_least_one_endorsement.all(:order => "users.id asc")
        row = 0
        for e in u.endorsements.active.by_position
          row += 1
          e.update_attribute(:position,row) unless e.position == row
          u.update_attribute(:top_endorsement_id,e.id) if u.top_endorsement_id != e.id and row == 1
        end
        puts u.login
      end
    end
  end
  
  desc "fix top endorsement"
  task :fix_top_endorsements => :environment do
    for govt in Government.active.all
      govt.switch_db    
      for u in User.find_by_sql("select * from users where top_endorsement_id not in (select id from endorsements)")
        u.top_endorsement = u.endorsements.active.by_position.find(:all, :limit => 1)[0]
        u.save_with_validation(false)        
        puts u.login
      end
    end
  end  
  
  desc "fix discussion counts"
  task :fix_discussion_counts => :environment do
    for govt in Government.active.all
      govt.switch_db    
      priorities = Priority.find(:all)
      for p in priorities
        p.update_attribute("discussions_count",p.activities.discussions.for_all_users.active.size) if p.activities.discussions.for_all_users.active.size != p.discussions_count
      end
      points = Point.find(:all)
      for p in points
        p.update_attribute("discussions_count",p.activities.discussions.for_all_users.active.size) if p.activities.discussions.for_all_users.active.size != p.discussions_count
      end    
    end
  end
  
  desc "fix tag counts"
  task :fix_tag_counts => :environment do
    for govt in Government.active.all
      govt.switch_db    
      for t in Tag.all
        t.update_counts
        t.save_with_validation(false)
      end
    end
  end  

  desc "fix comment participant dupes"
  task :fix_comment_participants => :environment do
    for govt in Government.active.all
      govt.switch_db    
      Activity.record_timestamps = false
      user_id = nil
      activity_id = nil
      for ac in ActivityCommentParticipant.active.find(:all, :order => "activity_id asc, user_id asc")
        if activity_id == ac.activity_id and user_id == ac.user_id
          ac.destroy
        else
          activity_id = ac.activity_id
          user_id = ac.user_id
          ac.update_attribute(:comments_count,ac.activity.comments.published.count(:conditions => ["user_id = ?",user_id]))
        end
      end
      Activity.record_timestamps = true
    end
  end
  
  desc "fix helpful counts"
  task :fix_helpful_counts => :environment do
    for govt in Government.active.all
      govt.switch_db
          
      endorser_helpful_points = Point.find_by_sql("SELECT points.*, count(*) as number
      FROM points INNER JOIN endorsements ON points.priority_id = endorsements.priority_id
      	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
      where endorsements.value  =1
      and point_qualities.value = 1
      group by points.id
      having number <> endorser_helpful_count")
      for point in endorser_helpful_points
        point.update_attribute("endorser_helpful_count",point.number)
      end
    
      endorser_helpful_points = Document.find_by_sql("SELECT documents.*, count(*) as number
      FROM documents INNER JOIN endorsements ON documents.priority_id = endorsements.priority_id
      	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
      where endorsements.value  =1
      and document_qualities.value = 1
      group by documents.id
      having number <> endorser_helpful_count")
      for doc in endorser_helpful_points
        doc.update_attribute("endorser_helpful_count",doc.number)
      end    
  
      opposer_helpful_points = Point.find_by_sql("SELECT points.*, count(*) as number
      FROM points INNER JOIN endorsements ON points.priority_id = endorsements.priority_id
      	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
      where endorsements.value = -1
      and point_qualities.value = 1
      group by points.id
      having number <> opposer_helpful_count")
      for point in opposer_helpful_points
        point.update_attribute("opposer_helpful_count",point.number)
      end  
    
      opposer_helpful_points = Document.find_by_sql("SELECT documents.*, count(*) as number
      FROM documents INNER JOIN endorsements ON documents.priority_id = endorsements.priority_id
      	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
      where endorsements.value = -1
      and document_qualities.value = 1
      group by documents.id
      having number <> opposer_helpful_count")
      for doc in opposer_helpful_points
        doc.update_attribute("opposer_helpful_count",doc.number)
      end    
    
      endorser_unhelpful_points = Point.find_by_sql("SELECT points.*, count(*) as number
      FROM points INNER JOIN endorsements ON points.priority_id = endorsements.priority_id
      	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
      where endorsements.value = 1
      and point_qualities.value = 0
      group by points.id
      having number <> endorser_unhelpful_count")
      for point in endorser_unhelpful_points
        point.update_attribute("endorser_unhelpful_count",point.number)
      end  
    
      endorser_unhelpful_points = Document.find_by_sql("SELECT documents.*, count(*) as number
      FROM documents INNER JOIN endorsements ON documents.priority_id = endorsements.priority_id
      	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
      where endorsements.value  =1
      and document_qualities.value = 0
      group by documents.id
      having number <> endorser_unhelpful_count")
      for doc in endorser_unhelpful_points
        doc.update_attribute("endorser_unhelpful_count",doc.number)
      end    
    
      opposer_unhelpful_points = Point.find_by_sql("SELECT points.*, count(*) as number
      FROM points INNER JOIN endorsements ON points.priority_id = endorsements.priority_id
      	 INNER JOIN point_qualities ON point_qualities.user_id = endorsements.user_id AND point_qualities.point_id = points.id
      where endorsements.value = -1
      and point_qualities.value = 0
      group by points.id
      having number <> opposer_unhelpful_count")
      for point in opposer_unhelpful_points
        point.update_attribute("opposer_unhelpful_count",point.number)
      end      
  
      opposer_unhelpful_points = Document.find_by_sql("SELECT documents.*, count(*) as number
      FROM documents INNER JOIN endorsements ON documents.priority_id = endorsements.priority_id
      	 INNER JOIN document_qualities ON document_qualities.user_id = endorsements.user_id AND document_qualities.document_id = documents.id
      where endorsements.value = -1
      and document_qualities.value = 0
      group by documents.id
      having number <> opposer_unhelpful_count")
      for doc in opposer_unhelpful_points
        doc.update_attribute("opposer_unhelpful_count",doc.number)
      end  
  
      #neutral counts
      Point.connection.execute("update points
      set neutral_unhelpful_count = unhelpful_count - endorser_unhelpful_count - opposer_unhelpful_count,
      neutral_helpful_count =  helpful_count - endorser_helpful_count - opposer_helpful_count")
      Document.connection.execute("update documents
      set neutral_unhelpful_count = unhelpful_count - endorser_unhelpful_count - opposer_unhelpful_count,
      neutral_helpful_count =  helpful_count - endorser_helpful_count - opposer_helpful_count")  
    end
  end  
  
  desc "fix user counts"
  task :fix_user_counts => :environment do
    for govt in Government.active.all
      govt.switch_db    
      users = User.find(:all)
      for u in users
        u.endorsements_count = u.endorsements.active.size
        u.up_endorsements_count = u.endorsements.active.endorsing.size
        u.down_endorsements_count = u.endorsements.active.opposing.size
        u.comments_count = u.comments.size
        u.document_revisions_count = u.document_revisions.published.size
        u.point_revisions_count = u.point_revisions.published.size      
        u.documents_count = u.documents.published.size
        u.points_count = u.points.published.size
        u.qualities_count = u.point_qualities.size + u.document_qualities.size
        u.save_with_validation(false)
      end
    end
  end
  
  desc "update obama endorsements on priorities"
  task :obama => :environment do
    for govt in Government.active.all
      govt.switch_db
      if govt.has_official?
        Priority.connection.execute("update priorities set obama_value = 1
        where obama_value <> 1 and id in (select priority_id from endorsements where user_id = #{govt.official_user_id} and value > 0 and status = 'active')")
        Priority.connection.execute("update priorities set obama_value = -1
        where obama_value <> -1 and id in (select priority_id from endorsements where user_id = #{govt.official_user_id} and value < 0 and status = 'active')")
        Priority.connection.execute("update priorities set obama_value = 0
        where obama_value <> 0 and id not in (select priority_id from endorsements where user_id = #{govt.official_user_id} and status = 'active')")
      end
    end
  end  
  
  desc "fix duplicate endorsements"
  task :fix_duplicate_endorsements => :environment do
    for govt in Government.active.all
      govt.switch_db    
      # get users with duplicate endorsements
      endorsements = Endorsement.find_by_sql("
          select user_id, priority_id, count(*) as num_times
          from endorsements
          group by user_id,priority_id
    	    having count(*) > 1
      ")
      for e in endorsements
        user = e.user
        priority = e.priority
        multiple_endorsements = user.endorsements.active.find(:all, :conditions => ["priority_id = ?",priority.id], :order => "endorsements.position")
        if multiple_endorsements.length > 1
          for c in 1..multiple_endorsements.length-1
            multiple_endorsements[c].destroy
          end
        end
      end
    end
  end
  
  desc "update talking point diffs"
  task :fix_point_diffs => :environment do
    for govt in Government.active.all
      govt.switch_db    
      for p in Point.find(:all)
        revisions = p.revisions.by_recently_created
        puts p.name
        for row in 0..revisions.length-1
          if row == revisions.length-1
            revisions[row].content_diff = revisions[row].content
          else
            revisions[row].content_diff = HTMLDiff.diff(revisions[row+1].content,revisions[row].content)
          end
          revisions[row].save_with_validation(false)
        end
      end
    end
  end
  
  desc "update document diffs"
  task :fix_document_diffs => :environment do
    for govt in Government.active.all
      govt.switch_db    
      for d in Document.find(:all)
        revisions = d.revisions.by_recently_created
        puts d.name
        for row in 0..revisions.length-1
          if row == revisions.length-1
            revisions[row].content_diff = revisions[row].content
          else
            revisions[row].content_diff = HTMLDiff.diff(RedCloth.new(revisions[row+1].content).to_html,RedCloth.new(revisions[row].content).to_html)
          end
          revisions[row].save_with_validation(false)
        end
      end
    end
  end  
  
end