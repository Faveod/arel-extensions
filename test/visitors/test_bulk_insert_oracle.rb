require 'helper'

module ArelExtensions
  module BulkInsertOracle
    describe 'the oracle bulk insert visitor' do
      before do
        @conn = FakeRecord::Base.new
        @visitor = Arel::Visitors::Oracle.new @conn.connection
        @table = Arel::Table.new(:users)
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

      it "should import large set of data in Oracle" do
        insert_manager = Arel::VERSION.to_i > 6 ? Arel::InsertManager.new().into(@table) : Arel::InsertManager.new(@conn).into(@table)
      	insert_manager.bulk_insert(@cols, @data)
      	sql = compile(insert_manager.ast)
      	sql.must_be_like %Q[INSERT ALL INTO "users" ("id", "name", "comments", "created_at") VALUES (23, 'nom1', 'sdfdsfdsfsdf', '2016-01-01') INTO "users" ("id", "name", "comments", "created_at") VALUES (25, 'nom2', 'sdfdsfdsfsdf', '2016-01-01') SELECT 1 FROM dual]
      end

	  end
  end
end