require 'helper'

module ArelExtensions
  module VisitorOracle
    describe 'the Oracle visitor' do
      before do
        @conn = FakeRecord::Base.new
        Arel::Table.engine = @conn
        @visitor = Arel::Visitors::Oracle.new @conn.connection
        @table = Arel::Table.new(:users)
        @attr = @table[:id]
        @date = Date.new(2016, 3, 31)
      end

      def compile node
        if Arel::VERSION.to_i > 5
          @visitor.accept(node, Arel::Collectors::SQLString.new).value
        else
          @visitor.accept(node)
        end
      end

      # Comparators

      it "should accept comparators on integers" do
        compile(@table[:id] == 42).must_match %{"users"."id" = 42}
        compile(@table[:id] == @table[:id]).must_be_like %{"users"."id" = "users"."id"}
        compile(@table[:id] != 42).must_match %{"users"."id" != 42}
        compile(@table[:id] > 42).must_match %{"users"."id" > 42}
        compile(@table[:id] >= 42).must_match %{"users"."id" >= 42}
        compile(@table[:id] >= @table[:id]).must_be_like %{"users"."id" >= "users"."id"}
        compile(@table[:id] < 42).must_match %{"users"."id" < 42}
        compile(@table[:id] <= 42).must_match %{"users"."id" <= 42}
        compile((@table[:id] <= 42).as('new_name')).must_match %{("users"."id" <= 42) AS new_name}
      end

      it "should accept comparators on dates" do
        c = @table[:created_at]
        u = @table[:updated_at]
        compile(c > @date).must_be_like %{"users"."created_at" > '2016-03-31'}
        compile(u >= @date).must_be_like %{"users"."updated_at" >= '2016-03-31'}
        compile(c < u).must_be_like %{"users"."created_at" < "users"."updated_at"}
      end

      it "should accept comparators on strings" do
        c = @table[:name]
        compile(c == 'test').must_be_like %{"users"."name" = 'test'}
        compile(c != 'test').must_be_like %{"users"."name" != 'test'}
        compile(c > 'test').must_be_like %{"users"."name" > 'test'}
        compile((c >= 'test').as('new_name')).must_be_like %{("users"."name" >= 'test') AS new_name}
        compile(c <= @table[:comments]).must_be_like %{"users"."name" <= "users"."comments"}
        compile(c =~ /\Atest\Z/).must_be_like %{REGEXP_LIKE("users"."name", '^test$')}
        compile(c =~ '^test$').must_be_like %{REGEXP_LIKE("users"."name", '^test$')}
        compile(c !~ /\Ate\Dst\Z/).must_be_like %{NOT REGEXP_LIKE("users"."name", '^te[^0-9]st$')}
        compile(c.imatches('%test%')).must_be_like %{LOWER("users"."name") LIKE LOWER('%test%')}
        compile(c.imatches_any(['%test%', 't2'])).must_be_like %{(LOWER("users"."name") LIKE LOWER('%test%') OR LOWER("users"."name") LIKE LOWER('t2'))}
        compile(c.idoes_not_match('%test%')).must_be_like %{LOWER("users"."name") NOT LIKE LOWER('%test%')}
      end

      # Maths
      # DateDiff
      it "should diff date col and date" do
        compile(@table[:created_at] - Date.new(2016, 3, 31)).must_match %{TO_DATE("users"."created_at") - TO_DATE('2016-03-31')}
      end

      it "should diff date col and datetime col" do
        compile(@table[:created_at] - @table[:updated_at]).must_match %{TO_DATE("users"."created_at") - TO_DATE("users"."updated_at")}
      end

      it "should diff date col and datetime col with AS" do
        sql = compile((@table[:updated_at] - @table[:created_at]).as('new_name'))
        sql.must_be_like %{(TO_DATE("users"."updated_at") - TO_DATE("users"."created_at")) AS new_name}
      end

      it "should diff between time values" do
        d2 = Time.new(2015,6,1)
        d1 = DateTime.new(2015,6,2)
        sql = compile(ArelExtensions::Nodes::DateDiff.new([d1,d2]))
        sql.must_match("TO_DATE('2015-06-02') - TO_DATE('2015-06-01')")
      end

      it "should diff between time values and time col" do
        d1 = DateTime.new(2015,6,2)
        sql = compile(ArelExtensions::Nodes::DateDiff.new([d1, @table[:updated_at]]))
        sql.must_match %{TO_DATE('2015-06-02') - TO_DATE("users"."updated_at")}
      end

      it "should accept operators on dates with numbers" do
        c = @table[:created_at]
        compile(c - 42).must_be_like %{DATE_SUB("users"."created_at", 42)}
        compile(c - @table[:id]).must_be_like %{DATE_SUB("users"."created_at", "users"."id")}
      end

      # Maths on sums
      it "should accept math operators on anything" do
        c = @table[:name]
        (c == 'test').to_sql.must_be_like %{"users"."name" = 'test'}
        (c != 'test').to_sql.must_be_like %{"users"."name" != 'test'}
        (c > 'test').to_sql.must_be_like %{"users"."name" > 'test'}
        compile((c >= 'test').as('new_name')).must_be_like %{("users"."name" >= 'test') AS new_name}
        compile(c <= @table[:comments]).must_be_like %{"users"."name" <= "users"."comments"}
        compile(c =~ /\Atest\Z/).must_be_like %{REGEXP_LIKE("users"."name", '^test$')}
        compile(c !~ /\Ate\Dst\Z/).must_be_like %{NOT REGEXP_LIKE("users"."name", '^te[^0-9]st$')}
      end

    end
  end
end