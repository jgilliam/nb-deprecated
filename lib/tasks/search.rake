namespace :search do  
  
  desc "reindex solr"
  task :reindex => :environment do
    puts "reindexing Priority"
    Priority.rebuild_solr_index
    puts "reindexing Point"
    Point.rebuild_solr_index
    puts "reindexing Document"
    Document.rebuild_solr_index
  end

end