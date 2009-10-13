# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true
config.cache_store = :mem_cache_store, 'localhost:11211'

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
config.action_mailer.raise_delivery_errors = false
config.action_mailer.delivery_method = :sendmail

if ENV['DOMAIN']
  config.action_controller.session = {:domain => '.' + ENV['DOMAIN']}
end

S3_CONFIG = { 'access_key_id' => ENV['S3_ACCESS_KEY_ID'], 'secret_access_key' => ENV['S3_SECRET_ACCESS_KEY'] }