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
config.action_controller.perform_caching             = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false