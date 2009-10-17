require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

Dir["#{File.dirname(__FILE__)}/lib/tasks/**/*.rake"].sort.each { |ext| load ext }

desc "Default Task"
task :default => [:test]

desc "Runs the unit tests"
task :test => "test:unit"

namespace :test do
  task :setup do
    ENV['RAILS_ENV'] = "test"
    require File.dirname(__FILE__) + '/config/solr_environment'
    puts "Using " + DB
    %x(mysql -u#{MYSQL_USER} < #{File.dirname(__FILE__) + "/test/fixtures/db_definitions/mysql.sql"}) if DB == 'mysql'

    Rake::Task["test:migrate"].invoke
  end
  
  desc 'Measures test coverage using rcov'
  task :rcov => :setup do
    rm_f "coverage"
    rm_f "coverage.data"
    rcov = "rcov --rails --aggregate coverage.data --text-summary -Ilib"
    
    system("#{rcov} --html #{Dir.glob('test/**/*_test.rb').join(' ')}")
    system("open coverage/index.html") if PLATFORM['darwin']
  end
  
  desc 'Runs the functional tests, testing integration with Solr'
  Rake::TestTask.new('functional' => :setup) do |t|
    t.pattern = "test/functional/*_test.rb"
    t.verbose = true
  end
  
  desc "Unit tests"
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'test/unit'
    t.pattern = "test/unit/*_shoulda.rb"
    t.verbose = true
  end
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_dir = "rdoc"
  rd.rdoc_files.exclude("lib/solr/**/*.rb", "lib/solr.rb")
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "websolr-rails"
    gem.summary = %Q{acts_as_solr compatible gem for websolr}
    gem.description = %Q{acts_as_solr compatible gem for websolr}
    gem.email = "kyle@kylemaxwell.com"
    gem.homepage = "http://github.com/onemorecloud/websolr-rails"
    gem.authors = ["Kyle Maxwell"]
    gem.add_development_dependency "thoughtbot-shoulda"
    gem.default_executable = %q{websolr}
    gem.rdoc_options = ["--main", "README.rdoc", "README.rdoc", "lib"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "websolr-rails #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
