namespace :arel_extensions do
	desc 'Install DB functions into current DB'
	task :install_functions => :environment do
		if ENV['DB'] == 'oracle' && ((defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx") || (RUBY_PLATFORM == 'java')) # not supported
          @env_db = (RUBY_PLATFORM == 'java' ? "jdbc-sqlite" : 'sqlite')
        else
          @env_db = ENV['DB'] || ActiveRecord::Base.connection.adapter_name
        end
        ActiveRecord::Base.establish_connection(Rails.env)
        @cnx = ActiveRecord::Base.connection
        if File.exist?("init/#{@env_db}.sql")
          sql = File.read("init/#{@env_db}.sql")
          unless sql.blank?
            @cnx.execute(sql) rescue $stderr << "can't create functions\n"
          end
        end
	end
end