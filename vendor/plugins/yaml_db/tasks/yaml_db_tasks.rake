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

		desc "Load contents of db/data.yml into database. Use file=<datafile> to specify the yaml file to load"
		task(:load => :environment) do
      file = ENV['file'] if ENV.include?("file")
      file ||= db_dump_data_file
      YamlDb.load file
		end
	end
end
