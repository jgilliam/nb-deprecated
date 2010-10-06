class Feed < ActiveRecord::Base

  has_many :webpages
  
  acts_as_taggable_on :issues

  def crawl
    posts = RssReader.posts_for(feed_link).reverse
    for post in posts
      link = post.link
      title = post.title
      puts link  
      # crap for crazy newsladder javascript redirect
      host = URI.parse(link).host.split('.')
      domain = host[host.length-2] + '.' + host[host.length-1]
      if ['newsladder.net'].include?(domain) # gotta parse out the actual url
        @response = ''
        begin
          Timeout::timeout(5) do   #times out after 5 seconds
            open(link, "User-Agent" => "White House 2",
                "From" => Government.current.admin_email,
                "Referer" => "http://<%= Government.current.base_url %>/") do |f|
                @response = f.read
            end
          end
        rescue Timeout::Error
          next
        end
        doc = Hpricot(@response)
        doc.search("script").each do |script|
          if script.inner_text.split("'").length == 3
            link = script.inner_text.split("'")[1]
            break
          end
        end
      end       
      # end of crap for newsladder
      
      # strip out source from blogrunner
      if ['blogrunner.com'].include?(domain)
        doc = Hpricot(post.description)
        doc.search("a").each do |a|
          link = a.attributes['href']
        end
        title = title.split(':')
        title.delete_at(0)
        title = title.join(': ').lstrip
      end
      
      # strip off url parameters on nytimes links
      link_host = URI.parse(link).host.split('.')
      link_domain = link_host[link_host.length-2] + '.' + link_host[link_host.length-1]
      if ['nytimes.com'].include?(link_domain)
        link = link.split('?').first
      end

      puts link
      webpage = Webpage.find_by_url(link)
      if not webpage
        webpage = Webpage.new(:url => link)
        if title.upcase == title # all caps
          webpage.title = title.titleize
        else
          webpage.title = title
        end
      end
      webpage.issue_list = issue_list unless webpage.attribute_present?("cached_issue_list")
      webpage.feed = self
      if domain != 'newsladder.net' and post.description
        webpage.description = post.description
      end
      # this generates an error for some unknown reason
      # webpage.published_at = post.pubDate
      webpage.save_with_validation(false)
    end
    self.update_attribute(:crawled_at, Time.now)  
  end

end
