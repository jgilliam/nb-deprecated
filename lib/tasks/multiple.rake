namespace :multiple do  

  desc "load new nations and send out welcome emails"
  task :new_nations => :environment do
    run_govt = Government.find_by_short_name('run')
    for govt in Government.pending.all
      # this will generate an error if the database already exists
      Government.connection.execute("CREATE DATABASE #{govt.db_name} character SET utf8 COLLATE utf8_general_ci")
      govt.switch_db
      file = "#{RAILS_ROOT}/db/schema.rb"
      load(file)
      User.connection.execute("ALTER TABLE rankings ENGINE=MYISAM")
      User.connection.execute("ALTER TABLE user_rankings ENGINE=MYISAM")    
      User.connection.execute("ALTER TABLE pictures ENGINE=MYISAM")
      
      next if User.admins.first
      @user = User.create(:login => govt.admin_name, :first_name => govt.admin_name.split(' ').first, :last_name => govt.admin_name.split(' ')[1..govt.admin_name.split(' ').length].join(' '), :email => govt.admin_email, :password => govt.password, :password_confirmation => govt.password, :status => "active")
      @user.is_admin = true
      @user.save_with_validation(false)
      CapitalGovernmentNew.create(:recipient => @user, :amount => 5)
      
      # create account on run.nationbuilder.com
      run_govt.switch_db
      run_user = User.find_by_email(govt.admin_email)
      if not run_user
        run_user = User.create(:login => govt.admin_name, :first_name => govt.admin_name.split(' ').first, :last_name => govt.admin_name.split(' ')[1..name.split(' ').length].join(' '), :email => govt.admin_email, :password => govt.password, :password_confirmation => govt.password, :status => "active")
      end

      # send welcome email
      govt.switch_db
      UserMailer.deliver_new_nation(govt,@user)
      govt.status = 'active'
      govt.password = nil
      govt.users_count = User.active.count
      govt.save_with_validation(false)
      govt.switch_db_back
    end
  end
  
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
        #
        # CURRENT BUG
        # this won't work.  you have to shut down the entire sphinx searchd and rebuild all the indexes to add a new one.
        #
        system("/usr/local/bin/indexer --config #{config_file} #{govt.short_name}_priority #{govt.short_name}_point #{govt.short_name}_document")
      end
    end
  end
  
end

    