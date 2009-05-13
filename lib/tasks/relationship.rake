namespace :relationship do  
  
  desc "endorsed_update"
  task :endorsed_update => :environment do
    for govt in Government.active.all
      govt.switch_db    
      priorities = Priority.published.tagged.top_rank.all
      for priority in priorities
        time_started = Time.now
        keep = []
        for p in priority.endorsers_endorsed(5)
          pct = (p.percentage.to_f*100).to_i
          next unless pct > 19
          rel = RelationshipEndorserEndorsed.find_by_priority_id_and_other_priority_id(priority.id,p.id)
          if rel
            rel.update_attribute("percentage",pct) unless rel.percentage == pct
          else
            rel = RelationshipEndorserEndorsed.create(:priority => priority, :other_priority => p, :percentage => pct)
          end
          keep << rel.id
        end
        for p in priority.undecideds_endorsed(5)
          pct = (p.percentage.to_f*100).to_i
          next unless pct > 19        
          rel = RelationshipUndecidedEndorsed.find_by_priority_id_and_other_priority_id(priority.id,p.id)
          if rel
            rel.update_attribute("percentage",pct) unless rel.percentage == pct
          else
            rel = RelationshipUndecidedEndorsed.create(:priority => priority, :other_priority => p, :percentage => pct)
          end
          keep << rel.id
        end
        for p in priority.opposers_endorsed(5)
          pct = (p.percentage.to_f*100).to_i
          next unless pct > 19        
          rel = RelationshipOpposerEndorsed.find_by_priority_id_and_other_priority_id(priority.id,p.id)
          if rel
            rel.update_attribute("percentage",pct) unless rel.percentage == pct
          else
            rel = RelationshipOpposerEndorsed.create(:priority => priority, :other_priority => p, :percentage => pct)
          end
          keep << rel.id
        end
        old_rels = Relationship.who_endorsed.find(:all, :conditions => ["id not in (?) and priority_id = ?",keep,priority.id])
        for rel in old_rels
          rel.destroy
        end
        puts govt.short_name + ': ' + priority.name + ' ' + (Time.now-time_started).seconds.to_s
      end
    end
  end
  
end