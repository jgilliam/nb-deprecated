namespace :multiple do  

  # THIS WHOLE THING NEEDS TO BE REVISITED IN HEROKU WORLD

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

end

    