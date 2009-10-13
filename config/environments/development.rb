# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false
config.cache_store = :mem_cache_store, 'localhost:11211'

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

DB_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/database.yml")
ENV['DOMAIN'] = DB_CONFIG[RAILS_ENV]['domain']
if ENV['DOMAIN']
  config.action_controller.session = {:domain => '.' + ENV['DOMAIN']}
end

ENV['FACEBOOK_API_KEY'] = DB_CONFIG[RAILS_ENV]['facebook_api_key'] 
ENV['FACEBOOK_SECRET_KEY'] = DB_CONFIG[RAILS_ENV]['facebook_secret_key']
ENV['TWITTER_KEY'] = DB_CONFIG[RAILS_ENV]['twitter_key'] 
ENV['TWITTER_SECRET_KEY'] = DB_CONFIG[RAILS_ENV]['twitter_secret_key']
ENV['HOPTOAD_KEY'] = DB_CONFIG[RAILS_ENV]['hoptoad_key']
ENV['TWITTER_LOGIN'] = DB_CONFIG[RAILS_ENV]['twitter_login']
ENV['TWITTER_PASSWORD'] = DB_CONFIG[RAILS_ENV]['twitter_password']
ENV['WEBSOLR_URL'] = DB_CONFIG[RAILS_ENV]['websolr_url']

S3_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/s3.yml")
Paperclip.options[:image_magick_path] = "/opt/local/bin"