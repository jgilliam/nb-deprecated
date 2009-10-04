namespace :facebook do  
  
  desc "register any unregistered facebook templates"
  task :register_templates => :environment do
    Government.current = Government.all.last    
    UserPublisher.register_all_templates
  end

end