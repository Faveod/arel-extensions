require 'arelx_test_helper'

module ArelExtensions
  module BulkInsertSQLlite
    describe 'the sqlite visitor can bulk insert' do
      before do
        @conn = FakeRecord::Base.new
        @visitor = Arel::Visitors::SQLite.new @conn.connection
        @table = Arel::Table.new(:users)
        Arel::Table.engine = @conn
        @cols = ['id', 'name', 'comments', 'created_at']
        @data = [
          [23, 'nom1', "sdfdsfdsfsdf", '2016-01-01'],
          [25, 'nom2', "sdfdsfdsfsdf", '2016-01-01']
        ]
      end

      def compile node
        if Arel::VERSION.to_i > 5
          @visitor.accept(node, Arel::Collectors::SQLString.new).value
        else
          @visitor.accept(node)
        end
      end

      it "should import large set of data" do
        insert_manager = Arel::VERSION.to_i > 6 ? Arel::InsertManager.new().into(@table) : Arel::InsertManager.new(@conn).into(@table)
        insert_manager.bulk_insert(@cols, @data)
        _(compile(insert_manager.ast))
          .must_be_like %Q[INSERT INTO "users" ("id", "name", "comments", "created_at")
                         SELECT 23 AS 'id', 'nom1' AS 'name', 'sdfdsfdsfsdf' AS 'comments', '2016-01-01' AS 'created_at' UNION ALL SELECT 25, 'nom2', 'sdfdsfdsfsdf', '2016-01-01']
      end
    end
  end
end
