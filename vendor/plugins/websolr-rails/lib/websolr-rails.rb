# Post-require hooks for acts_as_solr and sunspot if this 
# gem is loaded and WEBSOLR_URL is defined.

if ENV["WEBSOLR_URL"]
  require "uri"
  
  begin
    require "sunspot/rails/configuration"
    module Sunspot #:nodoc:
      module Rails #:nodoc:
        class Configuration
          def hostname
            URI.parse(ENV["WEBSOLR_URL"]).host
          end
          def port
            URI.parse(ENV["WEBSOLR_URL"]).port
          end
          def path
            URI.parse(ENV["WEBSOLR_URL"]).path
          end
        end
      end
    end
  rescue LoadError
    #ignore
  end

  begin
    require "acts_as_solr"
    module ActsAsSolr
      class Post        
        def self.execute(request)
          begin
            connection = Solr::Connection.new(ENV["WEBSOLR_URL"])
            return connection.send(request)
          rescue 
            raise "Couldn't connect to the Solr server at #{ENV["WEBSOLR_URL"]}. #{$!}"
            false
          end
        end
      end
    end
  rescue LoadError
    #ignore
  end

end