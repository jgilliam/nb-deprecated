require 'yaml_db'

namespace :db do
  
	desc "Dump schema and data to db/schema.rb and db/data.yml"
	task(:dump => [ "db:schema:dump", "db:data:dump" ])

	desc "Load schema and data from db/schema.rb and db/data.yml"
	task(:load => [ "db:schema:load", "db:data:load" ])

	namespace :data do
		def db_dump_data_file
			"#{RAILS_ROOT}/db/data.yml"
		end

		desc "Dump contents of database to db/data.yml. Optionally set tables=table1,table2,etc. if you want to restrict dump to specific tables. Use file=<datafile> to specify the file"
		task(:dump => :environment) do
      file = ENV['file'] if ENV.include?("file")
      file ||= db_dump_data_file
      YamlDb.dump file, ENV['tables']
		end

		desc "Dump contents of database to s3. Optionally set tables=table1,table2,etc. if you want to restrict dump to specific tables. Use file=<datafile> to specify the file"
		task(:dump_s3 => :environment) do
		  require 'aws/s3'
      file = File.join(RAILS_ROOT,"tmp",ENV['file']) if ENV.include?("file")
      file ||= File.join(RAILS_ROOT,"tmp","data.yml")
      file_name = file.split('/').last
      YamlDb.dump file, ENV['tables']
      AWS::S3::Base.establish_connection!(:access_key_id => S3_CONFIG['access_key_id'], :secret_access_key => S3_CONFIG['secret_access_key'])
      AWS::S3::S3Object.store(file_name, File.open(file), S3_CONFIG['bucket'], :access => :private)
		end

		desc "Load contents of db/data.yml into database. Use file=<datafile> to specify the yaml file to load"
		task(:load => :environment) do
      file = ENV['file'] if ENV.include?("file")
      file ||= db_dump_data_file
      YamlDb.load file
		end
		
		
		desc "Load contents of S3 file into database"
		task(:load_s3 => :environment) do
		  require 'aws/s3'
		  file = File.join(RAILS_ROOT,"tmp",ENV['file']) if ENV.include?("file")
      file ||= File.join(RAILS_ROOT,"tmp","data.yml")
      file_name = file.split('/').last
      AWS::S3::Base.establish_connection!(:access_key_id => S3_CONFIG['access_key_id'], :secret_access_key => S3_CONFIG['secret_access_key'])      
      open(file, 'w') do |f|
        AWS::S3::S3Object.stream(file_name, S3_CONFIG['bucket']) do |chunk|
          f.write chunk
        end
      end
      YamlDb.load file
		end
		
	end
	
end
