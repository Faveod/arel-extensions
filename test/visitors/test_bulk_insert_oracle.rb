require 'arelx_test_helper'

module ArelExtensions
  module BulkInsertOracle
    describe 'the oracle bulk insert visitor' do
      before do
        @conn = FakeRecord::Base.new
        @visitor = Arel::Visitors::Oracle.new @conn.connection
        @table = Arel::Table.new(:users)
        @cols = ['name', 'comments', 'created_at']
        @data = [
          ['nom1', 'sdfdsfdsfsdf', '2016-01-01'],
          ['nom2', 'sdfdsfdsfsdf', '2016-01-01']
        ]
      end

      def compile node
        if Arel::VERSION.to_i > 5
          @visitor.accept(node, Arel::Collectors::SQLString.new).value
        else
          @visitor.accept(node)
        end
      end

      it 'should import large set of data in Oracle' do
        insert_manager = Arel::VERSION.to_i > 6 ? Arel::InsertManager.new.into(@table) : Arel::InsertManager.new(@conn).into(@table)
        insert_manager.bulk_insert(@cols, @data)
        _(compile(insert_manager.ast))
          .must_be_like %Q[INSERT INTO "users" ("name", "comments", "created_at")
                        ((SELECT 'nom1', 'sdfdsfdsfsdf', '2016-01-01' FROM DUAL) UNION ALL (SELECT 'nom2', 'sdfdsfdsfsdf', '2016-01-01' FROM DUAL))]
      end
    end
  end
end
