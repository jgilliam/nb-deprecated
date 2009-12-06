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
          url = 'http://localhost:8983/solr'
        end
        connection = Solr::Connection.new(url)
        return connection.send(request)
      rescue 
        #raise "Couldn't connect to the Solr server at #{url}. #{$!}"
        false
      end
    end
  end

  module ClassMethods
  
    def multi_model_suffix(options)
      models = "AND (#{solr_configuration[:type_field]}:#{S3_CONFIG['bucket']}#{self.name}"
      models << " OR " + options[:models].collect {|m| "#{solr_configuration[:type_field]}:" + m.to_s}.join(" OR ") if options[:models].is_a?(Array)
      models << ")"
    end
  
  end
  
  module InstanceMethods
    # convert instance to Solr document
    def to_solr_doc
      logger.debug "to_solr_doc: creating doc for class: #{self.class.name}, id: #{record_id(self)}"
      doc = Solr::Document.new
      doc.boost = validate_boost(configuration[:boost]) if configuration[:boost]
      
      doc << {:id => solr_id,
              solr_configuration[:type_field] => S3_CONFIG['bucket']+self.class.name,
              solr_configuration[:primary_key_field] => record_id(self).to_s}

      # iterate through the fields and add them to the document,
      configuration[:solr_fields].each do |field_name, options|
        #field_type = configuration[:facets] && configuration[:facets].include?(field) ? :facet : :text
        
        field_boost = options[:boost] || solr_configuration[:default_boost]
        field_type = get_solr_field_type(options[:type])
        solr_name = options[:as] || field_name
        
        value = self.send("#{field_name}_for_solr")
        value = set_value_if_nil(field_type) if value.to_s == ""
        
        # add the field to the document, but only if it's not the id field
        # or the type field (from single table inheritance), since these
        # fields have already been added above.
        if field_name.to_s != self.class.primary_key and field_name.to_s != "type"
          suffix = get_solr_field_type(field_type)
          # This next line ensures that e.g. nil dates are excluded from the 
          # document, since they choke Solr. Also ignores e.g. empty strings, 
          # but these can't be searched for anyway: 
          # http://www.mail-archive.com/solr-dev@lucene.apache.org/msg05423.html
          next if value.nil? || value.to_s.strip.empty?
          [value].flatten.each do |v|
            v = set_value_if_nil(suffix) if value.to_s == ""
            field = Solr::Field.new("#{solr_name}_#{suffix}" => ERB::Util.html_escape(v.to_s))
            field.boost = validate_boost(field_boost)
            doc << field
          end
        end
      end
      
      add_includes(doc)
      logger.debug doc.to_xml
      doc
    end
  end
  
  module ParserMethods
    def solr_type_condition
      subclasses.inject("(#{solr_configuration[:type_field]}:#{S3_CONFIG['bucket']}#{self.name}") do |condition, subclass|
        condition << " OR #{solr_configuration[:type_field]}:#{subclass.name}"
      end << ')'
    end
  end
  
end