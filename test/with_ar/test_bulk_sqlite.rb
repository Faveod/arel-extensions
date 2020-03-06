require 'helper'

module ArelExtensions
  module WthAr

    describe 'the sqlite visitor' do

      before do
        ActiveRecord::Base.configurations = YAML.load_file('test/database.yml')
        ActiveRecord::Base.establish_connection(ENV['DB'] || (RUBY_PLATFORM == 'java' ? :"jdbc-sqlite" : :sqlite))
        ActiveRecord::Base.default_timezone = :utc
        @cnx = ActiveRecord::Base.connection
        Arel::Table.engine = ActiveRecord::Base
        @cnx.drop_table(:users) rescue nil
        @cnx.drop_table(:products) rescue nil
        @cnx.create_table :users do |t|
          t.column :age, :integer
          t.column :name, :string
          t.column :comments, :text
          t.column :created_at, :date
          t.column :updated_at, :date
          t.column :score, :decimal
        end
        @cnx.create_table :products do |t|
          t.column :price, :decimal
        end
        @table = Arel::Table.new(:users)
        @cols = ['id', 'name', 'comments', 'created_at']
        @data = [
              [23, 'nom1', "sdfdsfdsfsdf", '2016-01-01'],
              [25, 'nom2', "sdfdsfdsfsdf", '2016-01-01']
        ]
      end
      after do
        @cnx.drop_table(:users)
      end

      it "should import large set of data" do
        insert_manager = Arel::VERSION.to_i > 6 ? Arel::InsertManager.new().into(@table) : Arel::InsertManager.new(ActiveRecord::Base).into(@table)
        insert_manager.bulk_insert(@cols, @data)
        sql = insert_manager.to_sql
        sql.must_be_like %Q[INSERT INTO "users" ("id", "name", "comments", "created_at") SELECT 23 AS 'id', 'nom1' AS 'name', 'sdfdsfdsfsdf' AS 'comments', '2016-01-01' AS 'created_at' UNION ALL SELECT 25, 'nom2', 'sdfdsfdsfsdf', '2016-01-01']
      end

    end

  end
end
