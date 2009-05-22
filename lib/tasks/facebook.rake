namespace :facebook do  
  
  desc "register any unregistered facebook templates for all governments"
  task :register_templates => :environment do
    UserPublisher.register_all_templates
    if NB_CONFIG['multiple_government_mode']
      for govt in Government.active.facebook.all
        if govt.is_custom_domain?
          govt.switch_db
          UserPublisher.register_all_templates
        end
      end
    end
  end

end