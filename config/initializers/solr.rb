module ActsAsSolr
  
  class Post    
    def self.execute(request)
      begin
        if File.exists?(RAILS_ROOT+'/config/solr.yml')
          config = YAML::load_file(RAILS_ROOT+'/config/solr.yml')
          url = config[RAILS_ENV]['url']
          # for backwards compatibility
          url ||= "http://#{config[RAILS_ENV]['host']}:#{config[RAILS_ENV]['port']}/#{config[RAILS_ENV]['servlet_path']}"
        elsif ENV['WEBSOLR_URL']
          url = ENV['WEBSOLR_URL']
        else
          url = 'http://localhost:8982/solr'
        end
        connection = Solr::Connection.new(url)
        return connection.send(request)
      rescue 
        #raise "Couldn't connect to the Solr server at #{url}. #{$!}"
        false
      end
    end
  end
  
end