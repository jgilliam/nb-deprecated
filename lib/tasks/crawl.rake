namespace :crawl do  
  
  desc "webpages"
  task :webpages => :environment do
    Government.current = Government.all.last    
    Webpage.connection.execute("update webpages set title = null, description = null;")    
    webpages = Webpage.find(:all)
    for w in webpages
      w.crawl
      w.save
    end
  end
  
  desc "feeds"
  task :feeds => :environment do
    Government.current = Government.all.last    
    feeds = Feed.find(:all, :order => "rand()")
    for feed in feeds
      feed.crawl
      for issue in feed.issues
        Rails.cache.delete('views/issues_feed_column_' + issue.name)
      end
    end
  end
  
end