require 'helper'

module Arel
  module Nodes

    describe ArelExtensions::Comparators do
      it "< is equal lt" do
        relation = Arel::Table.new(:users)
        mgr = relation.project relation[:id]
        mgr.where relation[:id]<(10)
        res = mgr.to_sql
        res.must_be_like('SELECT "users"."id" FROM "users" WHERE "users"."id" < 10')
      end
      
      it "<= is equal lteq" do
        relation = Arel::Table.new(:users)
        mgr = relation.project relation[:id]
        mgr.where relation[:id]<=(10)
        res = mgr.to_sql
        res.must_be_like('SELECT "users"."id" FROM "users" WHERE "users"."id" <= 10')
      end

      it "> is equal gt" do
        relation = Arel::Table.new(:users)
        mgr = relation.project relation[:id]
        mgr.where relation[:id]>(10)
        res = mgr.to_sql
        res.must_be_like('SELECT "users"."id" FROM "users" WHERE "users"."id" > 10')
      end

      it "< is equal gteq" do
        relation = Arel::Table.new(:users)
        mgr = relation.project relation[:id]
        mgr.where relation[:id]>=(10)
        res = mgr.to_sql
        res.must_be_like('SELECT "users"."id" FROM "users" WHERE "users"."id" >= 10')
      end

      it "should compare with dates" do
        relation = Table.new(:users)
        mgr = relation.project relation[:created_at]
        mgr.where(relation[:created_at] >= Date.new(2016, 3, 31))
        mgr.to_sql.must_match %{"users"."created_at" >= '2016-03-31'}
      end

    end

  end
end