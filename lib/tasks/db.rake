namespace :db do
  
  desc "Migrate all the databases found in the main database through scripts in db/migrate. Target specific version with VERSION=x"
  task :migrate_all => :environment do
    for govt in Government.least_active.all
      govt.switch_db
      ActiveRecord::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
  end
  
end