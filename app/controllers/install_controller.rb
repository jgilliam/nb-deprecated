class InstallController < ApplicationController

  layout false

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
    current_government.switch_db_back
    Government.connection.execute("CREATE DATABASE #{current_government.db_name} character SET utf8 COLLATE utf8_general_ci")
    current_government.switch_db
    file = "#{RAILS_ROOT}/db/schema.rb"
    load(file)
    flash[:notice] = "Welcome to your nation!"
    redirect_to "/"
  end

end
