namespace :multiple do  
  
  desc "rewrites the entire search config file"
  task :rewrite_search_config => :environment do
    av = ActionView::Base.new(Rails::Configuration.new.view_path)
    File.open(RAILS_ROOT + "/config/" + RAILS_ENV + ".sphinx.conf", 'w') {|f| 
      f.write(av.render(:partial => "install/search_config")) 
      for govt in Government.active.all
        f.write(av.render(:partial => "install/search_govt", :locals => {:government => govt})) 
        govt.update_attribute(:is_searchable, 1)
      end
    }
  end
  
  desc "adds the latest search indexes to the config for new govts"
  task :new_search_config => :environment do
    config_file = RAILS_ROOT + "/config/" + RAILS_ENV + ".sphinx.conf"
    unsearchable_govts = Government.unsearchable.all
    if unsearchable_govts.any? 
      av = ActionView::Base.new(Rails::Configuration.new.view_path)
      File.open(config_file, 'a') {|f| 
        for govt in unsearchable_govts
          f.write(av.render(:partial => "install/search_govt", :locals => {:government => govt})) 
          govt.update_attribute(:is_searchable, 1)
        end
      }
      for govt in unsearchable_govts # now actually create the first index
        system("/usr/local/bin/indexer --config #{config_file} #{govt.short_name}_priority #{govt.short_name}_point #{govt.short_name}_document")
      end
    end
  end
  
end

    