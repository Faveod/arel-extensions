require 'helper'

module ArelExtensions
  module Nodes

    describe ArelExtensions::Comparators do

      before do
        @conn = FakeRecord::Base.new
        Arel::Table.engine = @conn
        @visitor = Arel::Visitors::ToSql.new @conn.connection
        @table = Arel::Table.new(:users)
        @attr = @table[:id]
        @date = Date.new(2016, 3, 31)
        @price = Arel::Table.new(:products)[:price]
      end

      def compile node
        @visitor.accept(node, Arel::Collectors::SQLString.new).value
      end

      it "< is equal lt" do
        compile(@table[:id] < 10).must_be_like('"users"."id" < 10')
      end

      it "<= is equal lteq" do
        compile(@table[:id] <= 10).must_be_like('"users"."id" <= 10')
      end

      it "> is equal gt" do
        compile(@table[:id] > 10).must_be_like('"users"."id" > 10')
      end

      it "< is equal gteq" do
        compile(@table[:id] >= 10).must_be_like('"users"."id" >= 10')
      end

      it "should compare with dates" do
        compile(@table[:created_at] >= Date.new(2016, 3, 31)).must_be_like %{"users"."created_at" >= '2016-03-31'}
      end

    end

  end
end
