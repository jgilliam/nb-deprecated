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
  
  desc "find new research requests from hello congress"
  task :congress_research => :environment do
    Government.find(1).switch_db
    for c in CongressResearch.find(:all, :order => "created_at desc")
      task = ResearchTask.find_by_requester_name_and_name(c.requester,c.name)
      if not task
        task = ResearchTask.create(:requester_name => c.requester, :requester_organization => c.organization, :requester_email => c.email, :name => c.name, :content => c.content)
        task.legislator = Legislator.find(c.legislator.wh2_id)
        task.tag = Tag.find(c.issue.wh2_id)
        task.save_with_validation(false)
      end
    end
  end  
  
end