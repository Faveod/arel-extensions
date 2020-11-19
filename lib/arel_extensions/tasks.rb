namespace :arel_extensions do
  desc 'Install DB functions into current DB'
  task install_functions: :environment do
    @env_db = if ENV['DB'] == 'oracle' && ((defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx") || (RUBY_PLATFORM == 'java')) # not supported
                (RUBY_PLATFORM == 'java' ? "jdbc-sqlite" : 'sqlite')
              else
                ENV['DB'] || ActiveRecord::Base.connection.adapter_name
              end
    ActiveRecord::Base.establish_connection(Rails.env.to_sym)
    CommonSqlFunctions.new(ActiveRecord::Base.connection).add_sql_functions(@env_db)
  end
end
