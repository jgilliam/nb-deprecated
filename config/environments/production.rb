# Settings specified here will take precedence over those in config/environment.rb

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
config.action_controller.session = {
  :session_domain => '.whitehouse2.org',  
  :session_key => '_wh2_session',
  :secret      => '97666fd8afb06371a3b9f5f9a88176f57e27d5ff893293b9975dc6e46b3d2b81f20c7b9d0e4abebf0ea6a9999983914582f3cb70d83b03ea1a5d00afeff5ba7d'
}

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
