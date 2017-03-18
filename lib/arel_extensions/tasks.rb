namespace :arelextensions do
	desc 'Install DB functions'
	task :install_functions => :environment do
        if ENV['DB'] == 'oracle' && ((defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx") || (RUBY_PLATFORM == 'java')) # not supported
          @env_db = (RUBY_PLATFORM == 'java' ? "jdbc-sqlite" : 'sqlite')
        else
          @env_db = ENV['DB']
        end
        ActiveRecord::Base.establish_connection(@env_db.try(:to_sym) || (RUBY_PLATFORM == 'java' ? :"jdbc-sqlite" : :sqlite))
        @cnx = ActiveRecord::Base.connection
        if File.exist?("init/#{@env_db}.sql")
          sql = File.read("init/#{@env_db}.sql")
          unless sql.blank?
            @cnx.execute(sql) rescue $stderr << "can't create functions\n"
          end
        end
	end
end