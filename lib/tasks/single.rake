namespace :single do  
  
  desc "the initial database records needed for a single government installation"
  task :start => :environment do
    Government.create(:status => "active", :short_name => "mygov", :layout => "basic", :name => "My Government", :tagline => "Where YOU set the priorities", :email => "youremail@youremailaddress.com", :target => "our nation", :is_facebook => 0, :admin_name => "Administrator", :admin_email => "adminemail@youremailaddress.com", :color_scheme_id => 1, :mission => "Make our country better", :prompt => "Our nation should:")
    ColorScheme.create(:input => "FFFFFF")

    @user = User.create(:login => current_government.admin_name, :first_name => "Administrator", :last_name => "Account", :email => current_government.admin_email, :password => "blahblah", :password_confirmation => "blahblah", :is_admin => true)
    @user.reset_password
    
    CapitalGovernmentNew.create(:recipient => @user, :amount => 5)
    
    # these tables should be MyISAM, not InnoDB. you will want to comment this out if you aren't using MySQL
    Government.connection.execute("ALTER TABLE rankings ENGINE=MYISAM")
    Government.connection.execute("ALTER TABLE user_rankings ENGINE=MYISAM")    
    Government.connection.execute("ALTER TABLE pictures ENGINE=MYISAM")
  end
  
end