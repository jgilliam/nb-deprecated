require 'websolr'

module ActsAsSolr
  class Post    
    def self.execute(request)
      begin
        unless url = ENV["WEBSOLR_URL"]
          return false
          #raise "WEBSOLR_URL was not defined.  Have you run websolr configure?"
        end
        connection = Solr::Connection.new(url)
        return connection.send(request)
      rescue 
        raise ActsAsSolr::ConnectionError, "Couldn't connect to the Solr server at #{url}. #{$!}"
        false
      end
    end
  end
  
end