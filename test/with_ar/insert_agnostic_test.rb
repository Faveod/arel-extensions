require 'helper'
require 'date'

module ArelExtensions
  module WthAr

    class InsertManagerTest < Minitest::Test
      def setup_db
        ActiveRecord::Base.configurations = YAML.load_file('test/database.yml')
        if ENV['DB'] == 'oracle' && ((defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx") || (RUBY_PLATFORM == 'java')) # not supported
          @env_db = (RUBY_PLATFORM == 'java' ? "jdbc-sqlite" : 'sqlite')
          skip "Platform not supported"
        else
          @env_db = ENV['DB']
        end
        ActiveRecord::Base.establish_connection(@env_db.try(:to_sym) || (RUBY_PLATFORM == 'java' ? :"jdbc-sqlite" : :sqlite))
        ActiveRecord::Base.default_timezone = :utc
        @cnx = ActiveRecord::Base.connection
        Arel::Table.engine = ActiveRecord::Base
        if File.exist?("init/#{@env_db}.sql")
          sql = File.read("init/#{@env_db}.sql")
          @cnx.execute(sql) unless sql.blank?
        end
        @cnx.drop_table(:user_tests) rescue nil 
        @cnx.create_table :user_tests do |t|
          t.column :age, :integer
          t.column :name, :string
          t.column :comments, :text
          t.column :created_at, :date
          t.column :updated_at, :datetime
          t.column :score, :decimal, :precision => 20, :scale => 10
        end
      end

      def setup
        setup_db
        @table = Arel::Table.new(:user_tests)
        @cols = ['id', 'name', 'comments', 'created_at']
        @data = [
          [23, 'nom1', "sdfdsfdsfsdfsd fdsf dsf dsf sdf afdg fsdg sg sd gsdfg e 54435 344", '2016-01-01'],
          [25, 'nom2', "sdfdsfdsfsdf", '2016-01-01']
        ]
      end

      def teardown
        @cnx.drop_table(:user_tests)
      end

      # Math Functions
      def test_bulk_insert
        insert_manager = Arel::VERSION.to_i > 6 ? Arel::InsertManager.new().into(@table) : Arel::InsertManager.new(Arel::Table.engine).into(@table)
        insert_manager.bulk_insert(@cols, @data)
        @cnx.execute(insert_manager.to_sql)
      end

    end
  end
end