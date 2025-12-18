require 'arelx_test_helper'

module ArelExtensions
  module BulkInsertOracle
    describe 'the oracle bulk insert visitor' do
      before do
        @conn = FakeRecord::Base.new
        @visitor = Arel::Visitors::Oracle.new @conn.connection
        @table = Arel::Table.new(:users)
        @cols = %w[name comments created_at]
        @data = [
          %w[nom1 sdfdsfdsfsdf 2016-01-01],
          %w[nom2 sdfdsfdsfsdf 2016-01-01]
        ]
      end

      def compile node
        if AREL_VERSION > V5
          @visitor.accept(node, Arel::Collectors::SQLString.new).value
        else
          @visitor.accept(node)
        end
      end

      it 'should import large set of data in Oracle' do
        insert_manager = AREL_VERSION > V6 ? Arel::InsertManager.new.into(@table) : Arel::InsertManager.new(@conn).into(@table)
        insert_manager.bulk_insert(@cols, @data)
        _(compile(insert_manager.ast))
          .must_be_like %Q[INSERT INTO "users" ("name", "comments", "created_at")
                        ((SELECT 'nom1', 'sdfdsfdsfsdf', '2016-01-01' FROM DUAL) UNION ALL (SELECT 'nom2', 'sdfdsfdsfsdf', '2016-01-01' FROM DUAL))]
      end
    end
  end
end
