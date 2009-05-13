class InstallController < ApplicationController

  skip_before_filter :hijack_db
  skip_before_filter :check_subdomain
  skip_before_filter :check_blast_click
  skip_before_filter :check_priority
  skip_before_filter :check_referral
  skip_before_filter :check_suspension
  skip_before_filter :update_loggedin_at
  skip_before_filter :check_facebook
  
  require 'rake' 
  require 'rake/testtask' 
  require 'rake/rdoctask'   
  require 'tasks/rails'   

  def load_db
    User.connection.execute("CREATE DATABASE #{current_government.db_name} character SET utf8 COLLATE utf8_general_ci")
    config = Rails::Configuration.new
    new_spec = config.database_configuration[RAILS_ENV].clone
    new_spec["database"] = current_government.db_name
    ActiveRecord::Base.establish_connection(new_spec) 
    Rake::Task["db:schema:load"].invoke
  end

end
