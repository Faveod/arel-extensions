require 'arelx_test_helper'
require 'set'

module ArelExtensions
  module VisitorToSql
    describe 'the to_sql visitor' do
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
        if Arel::VERSION.to_i > 5
          @visitor.accept(node, Arel::Collectors::SQLString.new).value
        else
          @visitor.accept(node)
        end
      end

      describe "primitive methods" do
       it "should be able to recognize equal nodes" do
         c = @table[:id]
         _(c == 1).must_be :eql?, (c == 1)
         _((c == 1).right.hash).must_equal (c == 1).right.hash
         _((c == 1).hash).must_equal (c == 1).hash

         _([c == 1, c == 1].uniq).must_equal [c == 1]
       end
      end

      # Math Functions
      it "should not break Arel functions" do
        _(compile(@price + 42)).must_be_like %{("products"."price" + 42)}
        _(compile(@table[:id] + @table[:pas_en_base]))
          .must_be_like %{("users"."id" + "users"."pas_en_base")}
        _(compile(@table[:pas_en_base] + @table[:id]))
          .must_be_like %{("users"."pas_en_base" + "users"."id")}
        _(compile(@table[:id] - @table[:pas_en_base]))
          .must_be_like %{("users"."id" - "users"."pas_en_base")}
        _(compile(@table[:pas_en_base] - @table[:id]))
          .must_be_like %{("users"."pas_en_base" - "users"."id")}
        _(compile(@table[:id] * @table[:pas_en_base]))
          .must_be_like %{"users"."id" * "users"."pas_en_base"}
        _(compile(@table[:pas_en_base] * @table[:id]))
          .must_be_like %{"users"."pas_en_base" * "users"."id"}
      end

      it "should return right calculations on numbers" do
        # puts (@price.abs + 42).inspect
        _(compile(@price.abs + 42)).must_be_like %{(ABS("products"."price") + 42)}
        _(compile(@price.ceil + 42)).must_be_like %{(CEIL("products"."price") + 42)}
        _(compile(@price.floor + 42)).must_be_like %{(FLOOR("products"."price") + 42)}
        _(compile(@price.log10 + 42)).must_be_like %{(LOG10("products"."price") + 42)}
        _(compile(@price.power(42) + 42)).must_be_like %{(POW("products"."price", 42) + 42)}
        _(compile(@price.pow(42) + 42)).must_be_like %{(POW("products"."price", 42) + 42)}
        _(compile(@price.ceil + @price.floor)).must_be_like %{(CEIL("products"."price") + FLOOR("products"."price"))}
        _(compile((@price.ceil + @price.floor).abs)).must_be_like %{ABS((CEIL("products"."price") + FLOOR("products"."price")))}
        _(compile(@price.round + 42)).must_be_like %{(ROUND("products"."price") + 42)}
        _(compile(@price.round(2) + 42)).must_be_like %{(ROUND("products"."price", 2) + 42)}
        _(compile(Arel.rand + 42)).must_be_like %{(RAND() + 42)}
        _(compile(@price.sum + 42)).must_be_like %{(SUM("products"."price") + 42)}
        _(compile((@price + 42).sum)).must_be_like %{SUM(("products"."price" + 42))}
        _(compile((@price + 42).average)).must_be_like %{AVG(("products"."price" + 42))}
        _(compile((Arel.rand * 9).round + 42)).must_be_like %{(ROUND(RAND() * 9) + 42)}
        _(compile((Arel.rand * @price).round(2) + @price)).must_be_like %{(ROUND(RAND() * "products"."price", 2) + "products"."price")}

        _(compile(@price.std + 42)).must_be_like %{(STD("products"."price") + 42)}
        _(compile(@price.variance + 42)).must_be_like %{(VARIANCE("products"."price") + 42)}

        _(compile(@price.coalesce(0) - 42)).must_be_like %{(COALESCE("products"."price", 0) - 42)}
        _(compile(@price.sum - 42)).must_be_like %{(SUM("products"."price") - 42)}
        _(compile(@price.std - 42)).must_be_like %{(STD("products"."price") - 42)}
        _(compile(@price.variance - 42)).must_be_like %{(VARIANCE("products"."price") - 42)}

        _(compile(@price * 42.0)).must_be_like %{"products"."price" * 42.0}
        _(compile(@price / 42.0)).must_be_like %{"products"."price" / 42.0}

        fake_table = Arel::Table.new('fake_tables')

        _(compile(fake_table[:fake_att] - 42)).must_be_like %{("fake_tables"."fake_att" - 42)}
        _(compile(fake_table[:fake_att].coalesce(0) - 42)).must_be_like %{(COALESCE("fake_tables"."fake_att", 0) - 42)}
      end

      # String Functions
      it "should accept functions on strings" do
        c = @table[:name]
        _(compile(c + 'test')).must_be_like %{CONCAT(\"users\".\"name\", 'test')}
        _(compile(c.length)).must_be_like %{LENGTH("users"."name")}
        # puts (c.length.round + 42).inspect
        _(compile(c.length.round + 42)).must_be_like %{(ROUND(LENGTH("users"."name")) + 42)}
        _(compile(c.locate('test'))).must_be_like %{LOCATE('test', "users"."name")}
        _(compile(c & 42)).must_be_like %{FIND_IN_SET(42, "users"."name")}

        _(compile((c >= 'test').as('new_name'))).must_be_like %{("users"."name" >= 'test') AS new_name}
        _(compile(c <= @table[:comments])).must_be_like %{"users"."name" <= "users"."comments"}
        _(compile(c =~ /\Atest\Z/)).must_be_like %{"users"."name" REGEXP '^test$'}
        _(compile(c =~ /\Atest\z/)).must_be_like %{"users"."name" REGEXP '^test$'}
        _(compile(c !~ /\Ate\Dst\Z/)).must_be_like %{"users"."name" NOT REGEXP '^te[^0-9]st$'}
        _(compile(c.imatches('%test%'))).must_be_like %{"users"."name" ILIKE '%test%'}
        _(compile(c.imatches_any(['%test%', 't2']))).must_be_like %{(("users"."name" ILIKE '%test%') OR ("users"."name" ILIKE 't2'))}
        _(compile(c.idoes_not_match('%test%'))).must_be_like %{"users"."name" NOT ILIKE '%test%'}

        _(compile(c.substring(1))).must_be_like %{SUBSTRING("users"."name", 1)}
        _(compile(c + '0')).must_be_like %{CONCAT("users"."name", '0')}
        _(compile(c.substring(1) + '0')).must_be_like %{CONCAT(SUBSTRING("users"."name", 1), '0')}
        _(compile(c.substring(1) + c.substring(2))).must_be_like %{CONCAT(SUBSTRING("users"."name", 1), SUBSTRING("users"."name", 2))}
        _(compile(c.concat(c).concat(c))).must_be_like %{CONCAT("users"."name", "users"."name", "users"."name")}
        _(compile(c + c + c)).must_be_like %{CONCAT("users"."name", "users"."name", "users"."name")}

        # some optimization on concat
        _(compile(c + 'test' + ' chain')).must_be_like %{CONCAT(\"users\".\"name\", 'test chain')}
        _(compile(Arel::Nodes.build_quoted('test') + ' chain')).must_be_like %{'test chain'}
        _(compile(c + '' + c)).must_be_like %{CONCAT(\"users\".\"name\", \"users\".\"name\")}

        _(compile(c.md5)).must_be_like %{MD5(\"users\".\"name\")}
      end

      # Comparators

      it "should accept comparators on integers" do
        _(compile(@table[:id] == 42)).must_match %{"users"."id" = 42}
        _(compile(@table[:id] == @table[:id])).must_be_like %{"users"."id" = "users"."id"}
        _(compile(@table[:id] != 42)).must_match %{"users"."id" != 42}
        _(compile(@table[:id] > 42)).must_match %{"users"."id" > 42}
        _(compile(@table[:id] >= 42)).must_match %{"users"."id" >= 42}
        _(compile(@table[:id] >= @table[:id])).must_be_like %{"users"."id" >= "users"."id"}
        _(compile(@table[:id] < 42)).must_match %{"users"."id" < 42}
        _(compile(@table[:id] <= 42)).must_match %{"users"."id" <= 42}
        _(compile((@table[:id] <= 42).as('new_name'))).must_match %{("users"."id" <= 42) AS new_name}
        _(compile(@table[:id].count.eq 42)).must_match %{COUNT("users"."id") = 42}
        # _(compile(@table[:id].count == 42)).must_match %{COUNT("users"."id") = 42} # TODO
        # _(compile(@table[:id].count != 42)).must_match %{COUNT("users"."id") != 42}
        # _(compile(@table[:id].count >= 42)).must_match %{COUNT("users"."id") >= 42}
      end

      it "should accept comparators on dates" do
        c = @table[:created_at]
        u = @table[:updated_at]
        _(compile(c > @date)).must_be_like %{"users"."created_at" > '2016-03-31'}
        _(compile(u >= @date)).must_be_like %{"users"."updated_at" >= '2016-03-31'}
        _(compile(c < u)).must_be_like %{"users"."created_at" < "users"."updated_at"}
      end

      it "should accept comparators on strings" do
        c = @table[:name]
        _(compile(c == 'test')).must_be_like %{"users"."name" = 'test'}
        _(compile(c != 'test')).must_be_like %{"users"."name" != 'test'}
        _(compile(c > 'test')).must_be_like %{"users"."name" > 'test'}
        _(compile((c >= 'test').as('new_name'))).must_be_like %{("users"."name" >= 'test') AS new_name}
        _(compile(c <= @table[:comments])).must_be_like %{"users"."name" <= "users"."comments"}
        _(compile(c =~ /\Atest\Z/)).must_be_like %{"users"."name" REGEXP '^test$'}
        _(compile(c !~ /\Ate\Dst\Z/)).must_be_like %{"users"."name" NOT REGEXP '^te[^0-9]st$'}
        _(compile(c.imatches('%test%'))).must_be_like %{"users"."name" ILIKE '%test%'}
        _(compile(c.imatches_any(['%test%', 't2']))).must_be_like %{(("users"."name" ILIKE '%test%') OR ("users"."name" ILIKE 't2'))}
        _(compile(c.idoes_not_match('%test%'))).must_be_like %{"users"."name" NOT ILIKE '%test%'}
      end

      # Maths
      # DateDiff
      it "should diff date col and date" do
        _(compile(@table[:created_at] - Date.new(2016, 3, 31))).must_match %{DATEDIFF("users"."created_at", '2016-03-31')}
      end

      it "should diff date col and datetime col" do
        _(compile(@table[:created_at] - @table[:updated_at])).must_match %{DATEDIFF("users"."created_at", "users"."updated_at")}
      end

      it "should diff date col and datetime col with AS" do
        _(compile((@table[:updated_at] - @table[:created_at]).as('new_name')))
          .must_match %{TIMEDIFF("users"."updated_at", "users"."created_at") AS new_name}
      end

      it "should diff between time values" do
        d2 = Time.new(2015,6,1)
        d1 = DateTime.new(2015,6,2)
        _(compile(ArelExtensions::Nodes::DateDiff.new([d1, d2])))
          .must_match("DATEDIFF('2015-06-02', '2015-06-01')")
      end

      it "should diff between time values and time col" do
        d1 = DateTime.new(2015,6,2)
        _(compile(ArelExtensions::Nodes::DateDiff.new([d1, @table[:updated_at]])))
          .must_match %{DATEDIFF('2015-06-02', "users"."updated_at")}
      end

      it "should diff between date col and duration" do
        d1 = 10
        d2 = -10
        _(compile(@table[:created_at] - d1))
          .must_match %{DATE_SUB("users"."created_at", 10)}
        _(compile(@table[:created_at] - d2))
          .must_match %{DATE_SUB("users"."created_at", -10)}
      end

      it "should accept operators on dates with numbers" do
        c = @table[:created_at]
        # u = @table[:updated_at]
        _(compile(c - 42)).must_be_like %{DATE_SUB("users"."created_at", 42)}
        _(compile(c - @table[:id])).must_be_like %{DATE_SUB("users"."created_at", "users"."id")}
      end

      # Maths on sums
      it "should accept math operators on anything" do
        c = @table[:name]
        _((c == 'test').to_sql)
          .must_be_like %{"users"."name" = 'test'}
        _((c != 'test').to_sql)
          .must_be_like %{"users"."name" != 'test'}
        _((c > 'test').to_sql)
          .must_be_like %{"users"."name" > 'test'}
        _(compile((c >= 'test').as('new_name'))).must_be_like %{("users"."name" >= 'test') AS new_name}
        _(compile(c <= @table[:comments])).must_be_like %{"users"."name" <= "users"."comments"}
        _(compile(c =~ /\Atest\Z/)).must_be_like %{"users"."name" REGEXP '^test$'}
        _(compile(c !~ /\Ate\Dst\Z/)).must_be_like %{"users"."name" NOT REGEXP '^te[^0-9]st$'}
      end

      it "should manage complex formulas" do
        c = @table[:name]
        _(compile(
            (c.length / 42).round(2).floor > (@table[:updated_at] - Date.new(2000, 3, 31)).abs.ceil
          ))
          .must_be_like %{FLOOR(ROUND(LENGTH("users"."name") / 42, 2)) > CEIL(ABS(TIMEDIFF("users"."updated_at", '2000-03-31 00:00:00 UTC')))}
      end

      it "should accept aggregator like GROUP CONCAT" do
        _(@table.project(@table[:first_name].group_concat).group(@table[:last_name]).to_sql)
          .must_be_like %{SELECT GROUP_CONCAT("users"."first_name") FROM "users" GROUP BY "users"."last_name"}
        _(@table.project(@table[:first_name].group_concat('++')).group(@table[:last_name]).to_sql)
          .must_be_like %{SELECT GROUP_CONCAT("users"."first_name", '++') FROM "users" GROUP BY "users"."last_name"}
      end

      # Unions
      it "should accept union operators on queries and union nodes" do
        c = @table.project(@table[:name])
        _(compile(c + c))
          .must_be_like %{(SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")}
        _((c + c).to_sql)
          .must_be_like %{(SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")}
        _((c + (c + c)).to_sql)
          .must_be_like %{(SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")}
        _(((c + c) + c).to_sql)
          .must_be_like %{(SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")}
        _((c + c + c).to_sql)
          .must_be_like %{(SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")}
        _((c + c).as('union_table').to_sql)
          .must_be_like %{((SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")) union_table}
        c = @table.project(@table[:name])
        _(compile(c.union_all(c)))
          .must_be_like %{(SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")}
        _((c.union_all(c)).to_sql)
          .must_be_like %{(SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")}
        _((c.union_all(c.union_all(c))).to_sql)
          .must_be_like %{(SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")}
        _(((c.union_all(c)).union_all(c)).to_sql)
          .must_be_like %{(SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")}
        _((c.union_all(c).union_all(c)).to_sql)
          .must_be_like %{(SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")}
        _((c.union_all(c)).as('union_table').to_sql)
          .must_be_like %{((SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")) union_table}
      end

      # Case
      it "should accept case clause" do
        _(@table[:name].when("smith").then("cool").when("doe").then("fine").else("uncool").to_sql)
          .must_be_like %{CASE "users"."name" WHEN 'smith' THEN 'cool' WHEN 'doe' THEN 'fine' ELSE 'uncool' END}
        _(@table[:name].when("smith").then(1).when("doe").then(2).else(0).to_sql)
          .must_be_like %{CASE "users"."name" WHEN 'smith' THEN 1 WHEN 'doe' THEN 2 ELSE 0 END}
        _(ArelExtensions::Nodes::Case.new.when(@table[:name] == "smith").then(1).when(@table[:name] == "doe").then(2).else(0).to_sql)
          .must_be_like %{CASE WHEN "users"."name" = 'smith' THEN 1 WHEN "users"."name" = 'doe' THEN 2 ELSE 0 END}
        _(ArelExtensions::Nodes::Case.new(@table[:name]).when("smith").then(1).when("doe").then(2).else(0).to_sql)
          .must_be_like %{CASE "users"."name" WHEN 'smith' THEN 1 WHEN 'doe' THEN 2 ELSE 0 END}
        _(@table[:name].when("smith").then(1).when("doe").then(2).else(0).sum.to_sql)
          .must_be_like %{SUM(CASE "users"."name" WHEN 'smith' THEN 1 WHEN 'doe' THEN 2 ELSE 0 END)}
        _(@table[:name].when("smith").then("cool").else("uncool").matches('value',false).to_sql)
          .must_be_like %{CASE "users"."name" WHEN 'smith' THEN 'cool' ELSE 'uncool' END LIKE 'value'}
        _(@table[:name].when("smith").then("cool").else("uncool").imatches('value',false).to_sql)
          .must_be_like %{CASE "users"."name" WHEN 'smith' THEN 'cool' ELSE 'uncool' END ILIKE 'value'}
      end

      it "should be possible to use as/xas on anything" do
        {
          @table[:name] => %{"users"."name" AS alias},
          @table[:name].concat(' test') => %{CONCAT("users"."name", ' test') AS alias},
          (@table[:name] + ' test') => %{CONCAT("users"."name", ' test') AS alias},
          (@table[:age] + 42) => %{("users"."age" + 42) AS alias},
          @table[:name].coalesce('') => %{COALESCE("users"."name", '') AS alias},
          Arel::Nodes.build_quoted('test') => %{'test' AS alias},
          @table.project(@table[:name]) => %{(SELECT "users"."name" FROM "users") "alias"},
          @table[:name].when("smith").then("cool").else("uncool") => %{CASE "users"."name" WHEN 'smith' THEN 'cool' ELSE 'uncool' END AS alias},
        }.each do |exp, res|
          _(compile(exp.as('alias'))).must_be_like res
          _(compile(exp.xas('alias'))).must_be_like res

          no_as = res.gsub('AS alias', '')
          _(compile(exp.xas(nil))).must_be_like res
        end
      end

      it "should accept comparators on functions" do
        c = @table[:name]
        _(compile(c.soundex == 'test')).must_be_like %{SOUNDEX("users"."name") = 'test'}
        _(compile(c.soundex != 'test')).must_be_like %{SOUNDEX("users"."name") != 'test'}
        _(compile(c.length >= 0)).must_be_like %{LENGTH("users"."name") >= 0}
      end

      it "should accept in on select statement" do
        c = @table[:name]
        _(compile(c.in(@table.project(@table[:name]))))
          .must_be_like %{"users"."name" IN (SELECT "users"."name" FROM "users")}
      end

      it "should accept coalesce function properly even on none actual tables and attributes" do
        fake_at = Arel::Table.new('fake_table')
        _(compile(fake_at['fake_attribute'].coalesce('other_value')))
          .must_be_like %{COALESCE("fake_table"."fake_attribute", 'other_value')}
        _(compile(fake_at['fake_attribute'].coalesce('other_value1','other_value2')))
          .must_be_like %{COALESCE("fake_table"."fake_attribute", 'other_value1', 'other_value2')}
        _(compile(fake_at['fake_attribute'].coalesce('other_value1').coalesce('other_value2')))
          .must_be_like %{COALESCE(COALESCE("fake_table"."fake_attribute", 'other_value1'), 'other_value2')}
        _(compile(fake_at['fake_attribute'].coalesce('other_value').matches('truc')))
          .must_be_like %{COALESCE("fake_table"."fake_attribute", 'other_value') LIKE 'truc'}
        _(compile(fake_at['fake_attribute'].coalesce('other_value').imatches('truc')))
          .must_be_like %{COALESCE("fake_table"."fake_attribute", 'other_value') ILIKE 'truc'}
      end

      it "should be possible to cast nodes types" do
        _(compile(@table[:id].cast('char')))
          .must_be_like %{CAST("users"."id" AS char)}
        _(compile(@table[:id].coalesce(' ').cast('char')))
          .must_be_like %{CAST(COALESCE("users"."id", ' ') AS char)}
        _(compile(@table[:id].coalesce(' ').cast(:string)))
          .must_be_like %{CAST(COALESCE("users"."id", ' ') AS char)}
        _(compile(@table[:id].cast(:string).coalesce(' ')))
          .must_be_like %{COALESCE(CAST(\"users\".\"id\" AS char), ' ')}
        _(compile(@table[:id].cast('char') + ' '))
          .must_be_like %{CONCAT(CAST("users"."id" AS char), ' ')}
        _(compile(@table[:id].cast('int') + 2))
          .must_be_like %{(CAST("users"."id" AS int) + 2)}
      end

      describe "the function in" do
        it "should be possible to have nil element in the function IN" do
          _(compile(@table[:id].in(nil)))
            .must_be_like %{ISNULL("users"."id")}
          _(compile(@table[:id].in([nil])))
            .must_be_like %{ISNULL("users"."id")}
          _(compile(@table[:id].in([nil,1])))
            .must_be_like %{(ISNULL("users"."id")) OR ("users"."id" = 1)}
          _(compile(@table[:id].in([nil,1,2])))
            .must_be_like %{(ISNULL("users"."id")) OR ("users"."id" IN (1, 2))}
          _(compile(@table[:id].in(1)))
            .must_be_like %{"users"."id" IN (1)}
          _(compile(@table[:id].in([1])))
            .must_be_like %{"users"."id" = 1}
          _(compile(@table[:id].in([1,2])))
            .must_be_like %{"users"."id" IN (1, 2)}
          _(compile(@table[:id].in([])))
            .must_be_like %{1 = 0}
        end

        it "should be possible to correctly use a Range on an IN" do
          _(compile(@table[:id].in(1..4)))
            .must_be_like %{"users"."id" BETWEEN (1) AND (4)}
          _(compile(@table[:created_at].in(Date.new(2016, 3, 31)..Date.new(2017, 3, 31))))
            .must_be_like %{"users"."created_at" BETWEEN ('2016-03-31') AND ('2017-03-31')}
        end

        it "should be possible to use a list of values and ranges on an IN" do
          _(compile(@table[:id].in [1..10, 20, 30, 40..50]))
            .must_be_like %{("users"."id" IN (20, 30)) OR ("users"."id" BETWEEN (1) AND (10)) OR ("users"."id" BETWEEN (40) AND (50))}
          _(compile(@table[:created_at].in(Date.new(2016, 1, 1), Date.new(2016, 2, 1)..Date.new(2016, 2, 28), Date.new(2016, 3, 31)..Date.new(2017, 3, 31), Date.new(2018, 1, 1))))
            .must_be_like %{   ("users"."created_at" IN ('2016-01-01', '2018-01-01'))
                            OR ("users"."created_at" BETWEEN ('2016-02-01') AND ('2016-02-28'))
                            OR ("users"."created_at" BETWEEN ('2016-03-31') AND ('2017-03-31'))}
        end

        it "should respecting Grouping" do
          g = ->(*v) { Arel.grouping(v) }
          _(compile(g[@table[:id], @table[:age]].in [g[1, 42]]))
            .must_be_like %{("users"."id", "users"."age") IN ((1, 42))}
          _(compile(g[@table[:id], @table[:age]].in [g[1, 42], g[2, 51]]))
            .must_be_like %{("users"."id", "users"."age") IN ((1, 42), (2, 51))}

          _(compile(g[@table[:id], @table[:age]].in(g[1, 42], g[2, 51])))
            .must_be_like %{("users"."id", "users"."age") IN ((1, 42), (2, 51))}
        end
      end

      describe "the function not_in" do
        it "should be possible to have nil element in the function IN" do
          _(compile(@table[:id].not_in nil))
            .must_be_like %{NOT ISNULL("users"."id")}
          _(compile(@table[:id].not_in [nil]))
            .must_be_like %{NOT ISNULL("users"."id")}
          _(compile(@table[:id].not_in [nil,1]))
            .must_be_like %{(NOT ISNULL("users"."id")) AND ("users"."id" != 1)}
          _(compile(@table[:id].not_in [nil,1,2]))
            .must_be_like %{(NOT ISNULL("users"."id")) AND ("users"."id" NOT IN (1, 2))}
          _(compile(@table[:id].not_in 1))
            .must_be_like %{"users"."id" NOT IN (1)}
          _(compile(@table[:id].not_in [1]))
            .must_be_like %{"users"."id" != 1}
          _(compile(@table[:id].not_in [1,2]))
            .must_be_like %{"users"."id" NOT IN (1, 2)}
          _(compile(@table[:id].not_in []))
            .must_be_like %{1 = 1}
        end

        it "should be possible to correctly use a Range on an IN" do
          # FIXME: Should use NOT BETWEEN
          _(compile(@table[:id].not_in 1..4))
            .must_be_like %{NOT ("users"."id" BETWEEN (1) AND (4))}
          # FIXME: Should use NOT BETWEEN
          _(compile(@table[:created_at].not_in Date.new(2016, 3, 31)..Date.new(2017, 3, 31)))
            .must_be_like %{NOT ("users"."created_at" BETWEEN ('2016-03-31') AND ('2017-03-31'))}
        end

        it "should be possible to use a list of values and ranges on an IN" do
          _(compile(@table[:id].not_in [1..10, 20, 30, 40..50]))
            .must_be_like %{       ("users"."id" NOT IN (20, 30))
                            AND (NOT ("users"."id" BETWEEN (1) AND (10)))
                            AND (NOT ("users"."id" BETWEEN (40) AND (50)))}
          _(compile(@table[:created_at].not_in Date.new(2016, 1, 1), Date.new(2016, 2, 1)..Date.new(2016, 2, 28), Date.new(2016, 3, 31)..Date.new(2017, 3, 31), Date.new(2018, 1, 1)))
            .must_be_like %{   ("users"."created_at" NOT IN ('2016-01-01', '2018-01-01'))
                            AND (NOT ("users"."created_at" BETWEEN ('2016-02-01') AND ('2016-02-28')))
                            AND (NOT ("users"."created_at" BETWEEN ('2016-03-31') AND ('2017-03-31')))}
        end
      end

      it "should be possible to add and substract as much as we want" do
        c = @table[:name]
        _(compile(c.locate('test')+1))
          .must_be_like %{(LOCATE('test', "users"."name") + 1)}
        _(compile(c.locate('test')-1))
          .must_be_like %{(LOCATE('test', "users"."name") - 1)}
        _(compile(c.locate('test')+c.locate('test')))
          .must_be_like %{(LOCATE('test', "users"."name") + LOCATE('test', "users"."name"))}
        _(compile(c.locate('test')+1+c.locate('test')-1 + 1))
          .must_be_like %{((((LOCATE('test', "users"."name") + 1) + LOCATE('test', "users"."name")) - 1) + 1)}
      end

      it "should be possible to add and substract on some nodes" do
        c = @table[:name]
        _(compile(c.when(0,0).else(42) + 42)).must_be_like %{(CASE "users"."name" WHEN 0 THEN 0 ELSE 42 END + 42)}
        _(compile(c.when(0,0).else(42) - 42)).must_be_like %{(CASE "users"."name" WHEN 0 THEN 0 ELSE 42 END - 42)}
        _(compile(c.when(0,"0").else("42") + "42")).must_be_like %{CONCAT(CASE "users"."name" WHEN 0 THEN '0' ELSE '42' END, '42')}
      end

      it "should be possible to desc and asc on functions" do
        c = @table[:name]
        _(compile(c.asc))
          .must_be_like %{"users"."name" ASC}
        _(compile(c.substring(2).asc))
          .must_be_like %{SUBSTRING("users"."name", 2) ASC}
        _(compile(c.substring(2).desc))
          .must_be_like %{SUBSTRING("users"."name", 2) DESC}
        _(compile((c.locate('test')+1).asc))
          .must_be_like %{(LOCATE('test', "users"."name") + 1) ASC}
      end

      it "should be possible to call Table function on TableAlias" do
        t = @table
        a = t.alias("aliased_users")
        _(compile(a.join(t).join_sources))
            .must_be_like %{INNER JOIN \"users\"}
      end

      describe "logical functions" do
        it "should know about truth" do
          _(compile(Arel.false))
            .must_be_like %{1 = 0}

          _(compile(Arel::true))
            .must_be_like %{1 = 1}
        end

        it "boolean nodes should be variadic" do
          c = @table[:id]

          _(compile(Arel::Nodes::And.new))
            .must_be_like %{1 = 1}
          _(compile(Arel::Nodes::And.new(c == 1)))
            .must_be_like %{"users"."id" = 1}
          _(compile(Arel::Nodes::And.new(c == 1, c == 2)))
            .must_be_like %{("users"."id" = 1) AND ("users"."id" = 2)}
          _(compile(Arel::Nodes::And.new [c == 1, c == 2, c == 3]))
            .must_be_like %{("users"."id" = 1) AND ("users"."id" = 2) AND ("users"."id" = 3)}


          _(compile(Arel::Nodes::Or.new))
            .must_be_like %{1 = 0}
          _(compile(Arel::Nodes::Or.new(c == 1)))
            .must_be_like %{"users"."id" = 1}
          _(compile(Arel::Nodes::Or.new(c == 1, c == 2)))
            .must_be_like %{("users"."id" = 1) OR ("users"."id" = 2)}
          _(compile(Arel::Nodes::Or.new(c == 1, c == 2, c == 3)))
            .must_be_like %{("users"."id" = 1) OR ("users"."id" = 2) OR ("users"."id" = 3)}
          _(compile(Arel::Nodes::Or.new [c == 1, c == 2, c == 3]))
            .must_be_like %{("users"."id" = 1) OR ("users"."id" = 2) OR ("users"."id" = 3)}
        end

        it "should know trivial identities" do
          skip "For future optimization"
          c = @table[:id]
          _(compile(Arel::Nodes::And.new(Arel.true, c == 1)))
            .must_be_like %{"users"."id" = 1}
          _(compile(Arel::Nodes::And.new(Arel.false, c == 1)))
            .must_be_like %{1 = 0}
          _(compile(Arel::Nodes::And.new(c == 1, c == 1)))
            .must_be_like %{"users"."id" = 1}

          _(compile(Arel::Nodes::Or.new(Arel.true, c == 1)))
            .must_be_like %{1 = 1}
          _(compile(Arel::Nodes::Or.new(Arel.false, c == 1)))
            .must_be_like %{"users"."id" = 1}
          _(compile(Arel::Nodes::Or.new(c == 1, c == 1)))
            .must_be_like %{"users"."id" = 1}
        end

        it "should be possible to have multiple arguments on an OR or an AND node" do
          c = @table[:id]
          _(compile((c == 1).and))
            .must_be_like %{"users"."id" = 1}

          _(compile((c == 1).and(c == 2, c == 3)))
            .must_be_like %{("users"."id" = 1) AND ("users"."id" = 2) AND ("users"."id" = 3)}
          _(compile((c == 1).and([c == 2, c == 3])))
            .must_be_like %{("users"."id" = 1) AND ("users"."id" = 2) AND ("users"."id" = 3)}

          _(compile((c == 1).or))
            .must_be_like %{"users"."id" = 1}

          _(compile((c == 1).or(c == 2, c == 3)))
            .must_be_like %{("users"."id" = 1) OR ("users"."id" = 2) OR ("users"."id" = 3)}
          _(compile((c == 1).or([c == 2, c == 3])))
            .must_be_like %{("users"."id" = 1) OR ("users"."id" = 2) OR ("users"."id" = 3)}
        end

        it "should avoid useless nesting" do
          c = @table[:id]
          _(compile(((c == 1).and(c == 2)).and ((c == 3).and(c == 4))))
            .must_be_like %{("users"."id" = 1) AND ("users"."id" = 2) AND ("users"."id" = 3) AND ("users"."id" = 4)}
          _(compile(((c == 1).or(c == 2)).or ((c == 3).or(c == 4))))
            .must_be_like %{("users"."id" = 1) OR ("users"."id" = 2) OR ("users"."id" = 3) OR ("users"."id" = 4)}

          _(compile(((c == 1).or(c == 2)).and ((c == 3).or(c == 4))))
            .must_be_like %{(("users"."id" = 1) OR ("users"."id" = 2)) AND (("users"."id" = 3) OR ("users"."id" = 4))}
          _(compile(((c == 1).and(c == 2)).or ((c == 3).and(c == 4))))
            .must_be_like %{(("users"."id" = 1) AND ("users"."id" = 2)) OR (("users"."id" = 3) AND ("users"."id" = 4))}
        end
      end

      puts "AREL VERSION : " + Arel::VERSION.to_s
    end
  end
end
