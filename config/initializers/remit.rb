config_file = File.join(Rails.root, 'config', 'amazon_fps.yml')
config = YAML.load_file(config_file)[RAILS_ENV].symbolize_keys

FPS_ACCESS_KEY = config[:access_key]
FPS_SECRET_KEY = config[:secret_key]