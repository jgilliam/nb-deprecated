# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  
  require 'core_extensions'
  config.gem 'paperclip'
  config.gem 'sunlight', :version => '>= 0.9'  
  config.gem "RedCloth", :version => ">= 3.0.4", :source => "http://code.whytheluckystiff.net/"
  config.gem 'googlecharts', :version => '1.3.6', :lib => 'gchart'
  config.gem 'oauth', :version => '>= 0.3.1'
  config.gem 'twitter-auth', :version => '0.1.21', :lib => 'twitter_auth'
  config.gem 'hpricot', :version => '>= 0.6'
  config.gem 'liquid'
  config.gem 'dweinand-will_paginate', :lib => 'will_paginate', :source => 'http://gems.github.com/'
  config.gem 'facebooker', :version => '1.0.53'
  config.gem 'hoptoad_notifier'
  config.gem 'memcached'

  #config.gem 'curb', :version => '0.1.4'
  
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :user_observer

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  config.i18n.load_path += Dir[File.join(RAILS_ROOT, 'config', 'locales', '**', '*.{rb,yml}')] 
  config.i18n.default_locale = "en"
  
  NB_CONFIG = { 'api_exclude_fields' => [:ip_address, :user_agent, :referrer, :google_token, :google_crawled_at, :activation_code, :salt, :email, :first_name, :last_name, :crypted_password, :is_tagger, :partner_id, :ip_address, :user_agent, :remember_token, :remember_token_expires_at, :referrer, :zip, :birth_date, :city, :state, :is_comments_subscribed, :is_finished_subscribed, :is_followers_subscribed, :is_mergeable, :is_messages_subscribed, :is_newsletter_subscribed, :is_point_changes_subscribed, :is_votes_subscribed, :is_subscribed, :contacts_count, :contacts_invited_count, :contacts_members_count, :contacts_not_invited_count, :code, :rss_code, :address] }

end

HoptoadNotifier.configure do |config|
  config.api_key = ENV['HOPTOAD_KEY'] if ENV['HOPTOAD_KEY']
  config.development_lookup = false
end

require 'diff'
require 'open-uri'
require 'validates_uri_existence_of'
require 'timeout'
require 'memcached'

TagList.delimiter = ","

AutoHtml.add_filter(:redcloth) do |text|
  begin
    RedCloth.new(text).to_html
  rescue
    text
  end
end

# RAILS 2.3.2
# this is a temporary hack to get around the fact that rails puts memorystore in front of memcached
# won't freeze the objects any more

class ActiveSupport::Cache::MemoryStore
  def write(name, value, options = nil)
    super
    #@data[name] = value.freeze
    @data[name] = value
  end
end
