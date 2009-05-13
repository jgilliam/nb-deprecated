namespace :single do  
  
  desc "the initial database records needed for a single government installation"
  task :start => :environment do
    Government.create(:status => "active", :short_name => "mygov", :layout => "basic", :name => "My Government", :tagline => "Where YOU set the priorities", :email => "youremail@youremailaddress.com", :target => "our nation", :is_facebook => 0, :admin_name => "Administrator", :admin_email => "adminemail@youremailaddress.com", :color_scheme_id => 1, :mission => "Make our country better", :prompt => "Our nation should:")
    ColorScheme.create(:input => "FFFFFF")
  end
  
end