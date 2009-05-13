# Settings specified here will take precedence over those in config/environment.rb

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
config.action_controller.session = {
  :domain => 'jim.com',
  :session_key => '_wh2_session',
  :secret      => '97666fd8afb06371a3b9f5f9a88176f57e27d5ff893293b9975dc6e46b3d2b81f20c7b9d0e4abebf0ea6a9999983914582f3cb70d83b03ea1a5d00afeff5ba7d'
}

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test
