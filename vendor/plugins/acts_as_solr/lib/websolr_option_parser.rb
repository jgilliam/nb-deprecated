require 'optparse'

class WebsolrOptionParser < OptionParser
  attr_accessor :options
  
  def usage
"Usage: #{$0} COMMAND [INDEX_NAME] [options] 

    COMMANDs:
    local:start     - starts the local development server
    local:stop      - stops the local development server

    add             - creates a new index
    list            - shows your indexes
    delete          - deletes an index
    configure       - adds websolr to your current Rails app
    
"
  end
  
  def parse!
    super
    self.options[:command] = ARGV[0]
    self.options[:name] ||= ARGV[1]
  end
  
  def initialize
    self.options = {}
    super do |opts|
      
      yield opts if block_given?
  
      opts.banner = usage
  
      opts.on("-u", "--user=USER", "Your Websolr username") do |u|
        options[:user] = u
      end
  
      opts.on("-p", "--password=PASSWORD", "Your Websolr password") do |p|
        options[:pass] = p
      end
      
      opts.on("-n", "--name=NAME", "Name of the index") do |p|
        options[:name] = p
      end
      
      opts.on("-e", "--rails-env=ENV", "RAILS_ENV") do |p|
        options[:rails_env] = p
      end
      
      opts.on("-i", "--invitation=CODE", "Your invitation code") do |p|
        options[:invitation_code] = p
      end
  
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end
  end
end