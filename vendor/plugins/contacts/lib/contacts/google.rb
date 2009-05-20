require 'cgi'
require 'net/http'
require 'net/https'
require 'rubygems'
require 'hpricot'
require 'time'
require 'zlib'
require 'stringio'

module Contacts
  # == Fetching Google Contacts
  # 
  # Web applications should use
  # AuthSub[http://code.google.com/apis/contacts/developers_guide_protocol.html#auth_sub]
  # proxy authentication to get an authentication token for a Google account.
  # 
  # First, get the user to follow the following URL:
  # 
  #   Contacts::Google.authentication_url('http://mysite.com/invite')
  #
  # After he authenticates successfully, Google will redirect him back to the target URL
  # (specified as argument above) and provide the token GET parameter. Use it to create a
  # new instance of this class and request the contact list:
  #
  #   gmail = Contacts::Google.new('example@gmail.com', params[:token])
  #   contacts = gmail.contacts
  #   #-> [ ['Fitzgerald', 'fubar@gmail.com', 'fubar@example.com'],
  #         ['William Paginate', 'will.paginate@gmail.com'], ...
  #         ]
  #
  # == Storing a session token
  #
  # The basic token that you will get after the user has authenticated on Google is valid
  # for only one request. However, you can specify that you want a session token which
  # doesn't expire:
  # 
  #   Contacts::Google.authentication_url('http://mysite.com/invite', :session => true)
  #
  # When the user authenticates, he will be redirected back with a token which still isn't
  # a session token, but can be exchanged for one!
  #
  #   token = Contacts::Google.sesion_token(params[:token])
  #
  # Now you have a permanent token. Store it with other user data so you can query the API
  # on his behalf without him having to authenticate on Google each time.
  class Google
    DOMAIN      = 'www.google.com'
    AuthSubPath = '/accounts/AuthSub' # all variants go over HTTPS
    AuthScope   = "http://#{DOMAIN}/m8/feeds/"

    # URL to Google site where user authenticates. Afterwards, Google redirects to your
    # site with the URL specified as +target+.
    #
    # Options are:
    # * <tt>:scope</tt> -- the AuthSub scope in which the resulting token is valid
    #   (default: "http://www.google.com/m8/feeds/")
    # * <tt>:secure</tt> -- boolean indicating whether the token will be secure
    #   (default: false)
    # * <tt>:session</tt> -- boolean indicating if the token can be exchanged for a session token
    #   (default: false)
    def self.authentication_url(target, options = {})
      params = { :next => target,
                 :scope => AuthScope,
                 :secure => false,
                 :session => false
               }.merge(options)
               
      query = params.inject [] do |url, pair|
        unless pair.last.nil?
          value = case pair.last
            when TrueClass; 1
            when FalseClass; 0
            else pair.last
            end
          
          url << "#{pair.first}=#{CGI.escape(value.to_s)}"
        end
        url
      end.join('&')

      "https://#{DOMAIN}#{AuthSubPath}Request?#{query}"
    end

    # Makes an HTTPS request to exchange the given token with a session one. Session
    # tokens never expire, so you can store them in the database alongside user info.
    #
    # Returns the new token as string or nil if the parameter couln't be found in response
    # body.
    def self.session_token(token)
      http = Net::HTTP.new(DOMAIN, 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      response = http.request_get(AuthSubPath + 'SessionToken', auth_headers(token))

      pair = response.body.split(/\s+/).detect {|p| p.index('Token') == 0 }
      pair.split('=').last if pair
    end

    # User ID (email) and token are required here. By default, an AuthSub token from
    # Google is one-time only, which means you can only make a single request with it.
    def initialize(user_id, token)
      @user = user_id.to_s
      @headers = {
        'Accept-Encoding' => 'gzip',
        'User-Agent' => 'agent-that-accepts-gzip',
      }.update(self.class.auth_headers(token))
      @in_batch = false
    end
    
    PATH = {
      'contacts_full' => '/m8/feeds/contacts/default/full',
      'contacts_batch' => '/m8/feeds/contacts/default/full/batch',
      'groups_full' => '/m8/feeds/groups/default/full',
      'groups_batch' => '/m8/feeds/groups/default/full/batch',
    }

    def get(path, params) #:nodoc:
      response = Net::HTTP.start(DOMAIN) do |google|
        google.get(path + '?' + query_string(params), @headers)
      end

      raise FetchingError.new(response) unless response.is_a? Net::HTTPSuccess

      response
    end

    # Timestamp of last update. This value is available only after the XML
    # document has been parsed; for instance after fetching the contact list.
    def updated_at
      @updated_at ||= Time.parse @updated_string if @updated_string
    end

    # Timestamp of last update as it appeared in the XML document
    def updated_at_string
      @updated_string
    end

    def post(url, body, headers)
      if @in_batch
        @batch_request << [body, headers]
      else
        response = Net::HTTP.start(DOMAIN) do |google|
          google.post(url, body.to_s, @headers.merge(headers))
        end
        
        raise FetchingError.new(response) unless response.is_a? Net::HTTPSuccess

        response
      end
    end

    # Fetches, parses and returns the contact list.
    #
    # ==== Options
    # * <tt>:limit</tt> -- use a large number to fetch a bigger contact list (default: 200)
    # * <tt>:offset</tt> -- 0-based value, can be used for pagination
    # * <tt>:order</tt> -- currently the only value support by Google is "lastmodified"
    # * <tt>:descending</tt> -- boolean
    # * <tt>:updated_after</tt> -- string or time-like object, use to only fetch contacts
    #   that were updated after this date
    def contacts(options = {})
      params = { :limit => 200 }.update(options)
      response = get(PATH['contacts_full'], params)
      parse_contacts response_body(response)
    end
    
    # Fetches, parses and returns the group list.
    #
    # ==== Options
    # see contacts
    def groups(options = {})
      params = { :limit => 200 }.update(options)
      response = get(PATH['groups_full'], params)
      parse_groups response_body(response)
    end
    
    # Fetches all contacts in chunks of 200.
    #
    # For example: if you have 1000 contacts, this will render in 5 GET requests
    def all_contacts
      ret = []
      chunk_size = 200
      offset = 0
      
      while (chunk = contacts(:limit => chunk_size, :offset => offset)).size != 0
        ret.push(*chunk)
        offset += chunk_size
        break if chunk.size < chunk_size
      end
      ret
    end
    
    def all_groups
      ret = []
      chunk_size = 200
      offset = 0
      
      while (chunk = groups(:limit => chunk_size, :offset => offset)).size != 0
        ret.push(*chunk)
        offset += chunk_size
      end
      ret
    end
    
    def new_contact(attr = {})
      c = Contact.new(self)
      c.load_attributes(attr)
    end
    
    def new_group(attr = {})
      g = Group.new(self)
      g.load_attributes(attr)
    end
    
    def batch_contacts(&blk)
      batch(PATH['contacts_batch'], &blk)
    end
    
    def batch_groups(&blk)
      batch(PATH['groups_batch'], &blk)
    end
    
    def batch(url, &blk)
      # Init
      limit = 512 * 1024
      @batch_request = []
      @in_batch = true

      # Execute the block
      yield

      # Pack post-request in batch job(s)
      while !@batch_request.empty?
        doc = Hpricot("<?xml version='1.0' encoding='UTF-8'?>\n<feed/>", :xml => true)
        root = doc.root
        root['xmlns'] = 'http://www.w3.org/2005/Atom'
        root['xmlns:gContact'] = 'http://schemas.google.com/contact/2008'
        root['xmlns:gd'] = 'http://schemas.google.com/g/2005'
        root['xmlns:batch'] = 'http://schemas.google.com/gdata/batch'

        size = doc.to_s.size
        100.times do
          break if size >= limit || @batch_request.empty?
          r = @batch_request.shift

          # Get stuff for request
          headers = r[1]
          xml = r[0]

          # Delete all namespace attributes
          xml.root.attributes.each { |a,v| xml.root.remove_attribute(a) if a =~ /^xmlns/ }

          # Find out what to do
          operation = case headers['X-HTTP-Method-Override']
          when 'PUT'
            'update'
          when 'DELETE'
            'delete'
          else
            'insert'
          end
          
          xml.root.children << Hpricot.make("<batch:operation type='#{operation}'/>").first
          root.children << xml.root
          size += xml.root.to_s.size
        end
        
        #puts "Doing POST... (#{size} bytes)"
        @in_batch = false
        post(url, doc, 'Content-Type' => 'application/atom+xml')
        @in_batch = true
      end
      @in_batch = false
    end

    class Base
      attr_reader :gmail, :xml
      
      BASE_XML = "<entry><category scheme='http://schemas.google.com/g/2005#kind' /><title type='text' /></entry>"
      
      def initialize(gmail, xml = nil)
        xml = BASE_XML if xml.nil?
        @xml = Hpricot(xml.to_s, :xml => true)
        @gmail = gmail
      end
      
      def load_attributes(attr)
        attr.each do |k,v|
          self.send((k.to_s+"=").to_sym, v)
        end
        self
      end
      
      def new?
        @xml.at('id').nil?
      end
      
      def id
        @xml.at('id').inner_html unless new?
      end
      
      def name
        @xml.at('title').inner_html
      end
      
      def name=(str)
        @xml.at('title').inner_html = str
      end
      
      def updated_at
        t = @xml.at('updated')
        return nil if t.nil?
        Time.parse(t.inner_html)
      end
      
      def [](attr)
        el = get_extended_property(attr)
        return nil if el.nil?
        
        if el.has_attribute?('value')
          el['value']
        else
          Hpricot(el.inner_html)
        end
      end
      
      def []=(attr, value)
        el = get_extended_property(attr)
        
        # Create element if it not already exists
        if el.nil?
          @xml.root.children.push *Hpricot.make("<gd:extendedProperty name='#{attr}' />", :xml => true)
          el = get_extended_property(attr)
        end
        
        if value.kind_of?(Hpricot)
          # If value is valid XML, set as element content
          el.remove_attribute('value')
          el.inner_html = value.to_s
        else
          # If value is not XML, set as value-attribute
          el['value'] = value
          el.inner_html = ''
        end
        value
      end
      
      def create_url
        raise "Contacts::Google::Base must be subclassed!"
      end
      
      def edit_url
        @xml.at("link[@rel='edit']")['href'].gsub(/^http:\/\/www.google.com(\/.*)$/, '\1') unless new?
      end
      
      def create!
        raise "Cannot create existing entry" unless new?
        response = gmail.post(create_url, document_for_request, {
          'Content-Type' => 'application/atom+xml'
        })
      end
      
      def update!
        raise "Cannot update new entry" if new?
        response = gmail.post(edit_url, document_for_request,
          'Content-Type' => 'application/atom+xml',
          'X-HTTP-Method-Override' => 'PUT'
        )
      end

      def delete!
        raise "Cannot delete new entry" if new?
        gmail.post(edit_url, document_for_request,
          'X-HTTP-Method-Override' => 'DELETE'
        )
      end
      
      protected
        def document_for_request
          # Make a new document from this entry, specify :xml => true to make sure Hpricot
          # doesn't downcase all tags, which results in bad input to Google
          atom = Hpricot(@xml.to_s, { :xml => true })

          # Remove <updated> tag (not necessary, but results in smaller XML)
          # Make sure not to delete the <link> tags, they seem unnecessary
          # but result in strange errors while making batch requests
          (atom / 'updated').remove
          
          # Set the right namespaces
          root = atom.at('entry')
          root['xmlns'] = 'http://www.w3.org/2005/Atom'
          root['xmlns:gd'] = 'http://schemas.google.com/g/2005'
          root['xmlns:gContact'] = 'http://schemas.google.com/contact/2008'
          
          after_document_for_request_hook(atom)
        end
        
        def after_document_for_request_hook(xml)
          xml
        end
        
        def get_extended_property(attr)
          raise "Attribute naming error" if attr =~ /['\[\]]/
          @xml.at("gd:extendedProperty[@name='#{attr}']")
        end
    end

    class Contact < Base
      attr_reader :groups
      
      PRIMARY_EMAIL_TAG = "<gd:email rel='http://schemas.google.com/g/2005#home' primary='true' address='' />"
      
      def initialize(gmail, xml = nil)
        super(gmail, xml)
        
        if xml.nil?
          # Specific constructs for a contact
          @xml.at('category')['term'] = "http://schemas.google.com/contact/2008#contact"
          @xml.root.children.push *Hpricot.make(PRIMARY_EMAIL_TAG)
        end
        
        @groups = []
        (@xml / 'gContact:groupMembershipInfo').each do |e|
          @groups << e['href']
        end
        
        # All groups are saved in an array for easy access
        (@xml / 'gContact:groupMembershipInfo').remove
      end
      
      def create_url
        '/m8/feeds/contacts/default/full'
        PATH['contacts_full']
      end
      
      def email
        @xml.at('gd:email')['address']
      end
      
      def email=(str)
        @xml.at('gd:email')['address'] = str
      end
      
      def clear_groups!
        @groups = []
      end
      
      def add_group(group)
        href = get_group_href(group)
        return nil if @groups.include?(href)
        @groups << href
      end
      
      def remove_group(group)
        href = get_group_href(group)
        @groups.delete(href)
      end
      
      protected
        def get_group_href(group)
          raise "Needs Group object" unless group.instance_of?(Group)
          group.id
        end
        
        def after_document_for_request_hook(xml)
          str = ""
          @groups.each do |href|
            str << "<gContact:groupMembershipInfo deleted='false' href='#{href}' />"
          end
          xml.root.children.push *Hpricot.make(str, :xml => true)
          xml
        end
    end
    
    class Group < Base
      def initialize(gmail, xml = nil)
        super(gmail, xml)
        @xml.at('category')['term'] = 'http://schemas.google.com/contact/2008#group'
      end
      
      def create_url
        '/m8/feeds/groups/default/full'
      end
    end

    protected
      
      def response_body(response)
        unless response['Content-Encoding'] == 'gzip'
          puts 'no gzip'
          response.body
        else
          gzipped = StringIO.new(response.body)
          Zlib::GzipReader.new(gzipped).read
        end
      end

      def self.auth_headers(token)
        { 'Authorization' => %(AuthSub token=#{token.to_s.inspect}) }
      end
      
      def parse_contacts(body)
        parse_entries(body, lambda { |*args| Contact.new(*args) })
      end
      
      def parse_groups(body)
        parse_entries(body, lambda { |*args| Group.new(*args) })
      end
      
      def parse_entries(body, lmbd)
        doc = Hpricot::XML body
        entries = []
        
        if updated_node = doc.at('/feed/updated')
          @updated_string = updated_node.inner_text
        end
        
        (doc / '/feed/entry').each do |entry|
          entries << lmbd.call(self, entry)
        end
        entries
      end

      def query_string(params)
        params.inject [] do |url, pair|
          value = pair.last
          unless value.nil?
            key = case pair.first
              when :limit
                'max-results'
              when :offset
                value = value.to_i + 1
                'start-index'
              when :order
                url << 'sortorder=descending' if params[:descending].nil?
                'orderby'
              when :descending
                value = value ? 'descending' : 'ascending'
                'sortorder'
              when :updated_after
                value = value.strftime("%Y-%m-%dT%H:%M:%S%Z") if value.respond_to? :strftime
                'updated-min'
              else pair.first
              end
            
            url << "#{key}=#{CGI.escape(value.to_s)}"
          end
          url
        end.join('&')
      end
  end
end
