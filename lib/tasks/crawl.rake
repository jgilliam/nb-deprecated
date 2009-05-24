namespace :crawl do  
  
  desc "webpages"
  task :webpages => :environment do
    for govt in Government.active.all
      govt.switch_db    
      Webpage.connection.execute("update webpages set title = null, description = null;")    
      webpages = Webpage.find(:all)
      for w in webpages
        w.crawl
        w.save
      end
    end
  end
  
  desc "feeds"
  task :feeds => :environment do
    for govt in Government.active.all
      govt.switch_db    
      feeds = Feed.find(:all, :order => "rand()")
      for feed in feeds
        feed.crawl
        for issue in feed.issues
          Rails.cache.delete('views/' + Government.current.short_name + '-issues_feed_column_' + issue.name)
        end
      end
    end
  end
  
end