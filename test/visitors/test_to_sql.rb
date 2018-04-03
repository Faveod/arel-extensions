require 'helper'
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

      # Math Functions
      it "should not break Arel functions" do
        compile(@price + 42).must_be_like %{("products"."price" + 42)}
		compile(@table[:id] + @table[:pas_en_base])
			.must_be_like %{("users"."id" + "users"."pas_en_base")} 
		compile(@table[:pas_en_base] + @table[:id])
			.must_be_like %{("users"."pas_en_base" + "users"."id")} 
		compile(@table[:id] - @table[:pas_en_base])
			.must_be_like %{("users"."id" - "users"."pas_en_base")} 
		compile(@table[:pas_en_base] - @table[:id])
			.must_be_like %{("users"."pas_en_base" - "users"."id")} 			
		compile(@table[:id] * @table[:pas_en_base])
			.must_be_like %{"users"."id" * "users"."pas_en_base"} 
		compile(@table[:pas_en_base] * @table[:id])
			.must_be_like %{"users"."pas_en_base" * "users"."id"} 
      end

      it "should return right calculations on numbers" do
		#puts (@price.abs + 42).inspect
        compile(@price.abs + 42).must_be_like %{(ABS("products"."price") + 42)}
        compile(@price.ceil + 42).must_be_like %{(CEIL("products"."price") + 42)}
        compile(@price.floor + 42).must_be_like %{(FLOOR("products"."price") + 42)}
        compile(@price.log10 + 42).must_be_like %{(LOG10("products"."price") + 42)}
        compile(@price.power(42) + 42).must_be_like %{(POW("products"."price", 42) + 42)}
        compile(@price.pow(42) + 42).must_be_like %{(POW("products"."price", 42) + 42)}
        compile(@price.ceil + @price.floor).must_be_like %{(CEIL("products"."price") + FLOOR("products"."price"))}
        compile((@price.ceil + @price.floor).abs).must_be_like %{ABS((CEIL("products"."price") + FLOOR("products"."price")))}
        compile(@price.round + 42).must_be_like %{(ROUND("products"."price") + 42)}
        compile(@price.round(2) + 42).must_be_like %{(ROUND("products"."price", 2) + 42)}
        compile(Arel.rand + 42).must_be_like %{(RAND() + 42)}
        compile(@price.sum + 42).must_be_like %{(SUM("products"."price") + 42)}
        compile((@price + 42).sum).must_be_like %{SUM(("products"."price" + 42))}
        compile((@price + 42).average).must_be_like %{AVG(("products"."price" + 42))}
        compile((Arel.rand * 9).round + 42).must_be_like %{(ROUND(RAND() * 9) + 42)}        
        compile((Arel.rand * @price).round(2) + @price).must_be_like %{(ROUND(RAND() * "products"."price", 2) + "products"."price")}        
      end

      # String Functions
      it "should accept functions on strings" do
        c = @table[:name]
        compile(c + 'test').must_be_like %{CONCAT(\"users\".\"name\", 'test')}
        compile(c + 'test' + ' chain').must_be_like %{CONCAT(CONCAT(\"users\".\"name\", 'test'), ' chain')}
        compile(c.length).must_be_like %{LENGTH("users"."name")}
        #puts (c.length.round + 42).inspect
        compile(c.length.round + 42).must_be_like %{(ROUND(LENGTH("users"."name")) + 42)}
        compile(c.locate('test')).must_be_like %{LOCATE('test', "users"."name")}
        compile(c & 42).must_be_like %{FIND_IN_SET(42, "users"."name")}

        compile((c >= 'test').as('new_name')).must_be_like %{("users"."name" >= 'test') AS new_name}
        compile(c <= @table[:comments]).must_be_like %{"users"."name" <= "users"."comments"}
        compile(c =~ /\Atest\Z/).must_be_like %{"users"."name" REGEXP '^test$'}
        compile(c !~ /\Ate\Dst\Z/).must_be_like %{"users"."name" NOT REGEXP '^te[^0-9]st$'}
        compile(c.imatches('%test%')).must_be_like %{"users"."name" ILIKE '%test%'}
        compile(c.imatches_any(['%test%', 't2'])).must_be_like %{("users"."name" ILIKE '%test%' OR "users"."name" ILIKE 't2')}
        compile(c.idoes_not_match('%test%')).must_be_like %{"users"."name" NOT ILIKE '%test%'}
        
        compile(c.substring(1)).must_be_like %{SUBSTRING("users"."name", 1)}        
        compile(c + 'MACHIN').must_be_like %{CONCAT("users"."name", 'MACHIN')}
        compile(c.substring(1) + '0').must_be_like %{CONCAT(SUBSTRING("users"."name", 1), '0')}
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
        compile(c =~ /\Atest\Z/).must_be_like %{"users"."name" REGEXP '^test$'}
        compile(c !~ /\Ate\Dst\Z/).must_be_like %{"users"."name" NOT REGEXP '^te[^0-9]st$'}
        compile(c.imatches('%test%')).must_be_like %{"users"."name" ILIKE '%test%'}
        compile(c.imatches_any(['%test%', 't2'])).must_be_like %{("users"."name" ILIKE '%test%' OR "users"."name" ILIKE 't2')}
        compile(c.idoes_not_match('%test%')).must_be_like %{"users"."name" NOT ILIKE '%test%'}
      end

      # Maths
      # DateDiff
      it "should diff date col and date" do
        compile(@table[:created_at] - Date.new(2016, 3, 31)).must_match %{DATEDIFF("users"."created_at", '2016-03-31')}
      end

      it "should diff date col and datetime col" do
        compile(@table[:created_at] - @table[:updated_at]).must_match %{DATEDIFF("users"."created_at", "users"."updated_at")}
      end

      it "should diff date col and datetime col with AS" do
        sql = compile((@table[:updated_at] - @table[:created_at]).as('new_name'))
        sql.must_match %{TIMEDIFF("users"."updated_at", "users"."created_at") AS new_name}
      end

      it "should diff between time values" do
        d2 = Time.new(2015,6,1)
        d1 = DateTime.new(2015,6,2)
        sql = compile(ArelExtensions::Nodes::DateDiff.new([d1, d2]))
        sql.must_match("DATEDIFF('2015-06-02', '2015-06-01')")
      end

      it "should diff between time values and time col" do
        d1 = DateTime.new(2015,6,2)
        sql = compile(ArelExtensions::Nodes::DateDiff.new([d1, @table[:updated_at]]))
        sql.must_match %{DATEDIFF('2015-06-02', "users"."updated_at")}
      end
      
      it "should diff between date col and duration" do
		d1 = 10
		d2 = -10
        compile(@table[:created_at] - d1).
			must_match %{DATE_SUB("users"."created_at", 10)}
        compile(@table[:created_at] - d2).
			must_match %{DATE_SUB("users"."created_at", -10)}
      end

      it "should accept operators on dates with numbers" do
        c = @table[:created_at]
#        u = @table[:updated_at]
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
        compile(c =~ /\Atest\Z/).must_be_like %{"users"."name" REGEXP '^test$'}
        compile(c !~ /\Ate\Dst\Z/).must_be_like %{"users"."name" NOT REGEXP '^te[^0-9]st$'}
      end      

      it "should manage complex formulas" do
        c = @table[:name]
        compile(
          (c.length / 42).round(2).floor > (@table[:updated_at] - Date.new(2000, 3, 31)).abs.ceil
        ).must_be_like %{FLOOR(ROUND(LENGTH("users"."name") / 42, 2)) > CEIL(ABS(TIMEDIFF("users"."updated_at", '2000-03-31 00:00:00 UTC')))}
      end
      
      it "should accept aggregator like GROUP CONCAT" do
		@table.project(@table[:first_name].group_concat).group(@table[:last_name]).to_sql
			.must_be_like %{SELECT GROUP_CONCAT("users"."first_name") FROM "users" GROUP BY "users"."last_name"}			
		@table.project(@table[:first_name].group_concat('++')).group(@table[:last_name]).to_sql
			.must_be_like %{SELECT GROUP_CONCAT("users"."first_name", '++') FROM "users" GROUP BY "users"."last_name"}
      end
      
      # Unions       
      it "should accept union operators on queries and union nodes" do
		c = @table.project(@table[:name])
		compile(c + c)
			.must_be_like %{(SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")} 
		(c + c).to_sql
			.must_be_like %{(SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")}  
		(c + (c + c)).to_sql
			.must_be_like %{(SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")}      
		((c + c) + c).to_sql
			.must_be_like %{(SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")}      
		(c + c + c).to_sql
			.must_be_like %{(SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")}      
		
		(c + c).as('union_table').to_sql
			.must_be_like %{((SELECT "users"."name" FROM "users") UNION (SELECT "users"."name" FROM "users")) union_table}  			     
			
			
		c = @table.project(@table[:name])
		compile(c.union_all(c))
			.must_be_like %{(SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")} 
		(c.union_all(c)).to_sql
			.must_be_like %{(SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")}  
		(c.union_all(c.union_all(c))).to_sql
			.must_be_like %{(SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")}      
		((c.union_all(c)).union_all(c)).to_sql
			.must_be_like %{(SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")}      
		(c.union_all(c).union_all(c)).to_sql
			.must_be_like %{(SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")}      
		(c.union_all(c)).as('union_table').to_sql
			.must_be_like %{((SELECT "users"."name" FROM "users") UNION ALL (SELECT "users"."name" FROM "users")) union_table}  			     
			
	 end
	 
	 # Case
     it "should accept case clause" do		
		@table[:name].when("smith").then("cool").when("doe").then("fine").else("uncool").to_sql
			.must_be_like %{CASE "users"."name" WHEN 'smith' THEN 'cool' WHEN 'doe' THEN 'fine' ELSE 'uncool' END}  			     
		@table[:name].when("smith").then(1).when("doe").then(2).else(0).to_sql
			.must_be_like %{CASE "users"."name" WHEN 'smith' THEN 1 WHEN 'doe' THEN 2 ELSE 0 END}   
		ArelExtensions::Nodes::Case.new.when(@table[:name] == "smith").then(1).when(@table[:name] == "doe").then(2).else(0).to_sql
			.must_be_like %{CASE WHEN "users"."name" = 'smith' THEN 1 WHEN "users"."name" = 'doe' THEN 2 ELSE 0 END}  
		ArelExtensions::Nodes::Case.new(@table[:name]).when("smith").then(1).when("doe").then(2).else(0).to_sql
			.must_be_like %{CASE "users"."name" WHEN 'smith' THEN 1 WHEN 'doe' THEN 2 ELSE 0 END}  
		@table[:name].when("smith").then(1).when("doe").then(2).else(0).sum.to_sql
			.must_be_like %{SUM(CASE "users"."name" WHEN 'smith' THEN 1 WHEN 'doe' THEN 2 ELSE 0 END)} 
        @table[:name].when("smith").then("cool").else("uncool").matches('value',false).to_sql
            .must_be_like %{CASE "users"."name" WHEN 'smith' THEN 'cool' ELSE 'uncool' END LIKE 'value'}  			     									
        @table[:name].when("smith").then("cool").else("uncool").imatches('value',false).to_sql
            .must_be_like %{CASE "users"."name" WHEN 'smith' THEN 'cool' ELSE 'uncool' END ILIKE 'value'}  			     									
     end
     
     it "should be possible to use as on anything" do
		compile(@table[:name].as('alias')).must_be_like %{"users"."name" AS alias}
		compile(@table[:name].concat(' test').as('alias')).must_be_like %{CONCAT("users"."name", ' test') AS alias}		
		compile((@table[:name] + ' test').as('alias')).must_be_like %{CONCAT("users"."name", ' test') AS alias}
		compile((@table[:age] + 42).as('alias')).must_be_like %{("users"."age" + 42) AS alias}		
		compile(@table[:name].coalesce('').as('alias')).must_be_like %{COALESCE("users"."name", '') AS alias}
		compile(Arel::Nodes.build_quoted('test').as('alias')).must_be_like %{'test' AS alias}
		compile(@table.project(@table[:name]).as('alias')).must_be_like %{(SELECT "users"."name" FROM "users") alias}
		compile(@table[:name].when("smith").then("cool").else("uncool").as('alias')).
			must_be_like %{CASE "users"."name" WHEN 'smith' THEN 'cool' ELSE 'uncool' END AS alias}  			     									
     end
     
	  it "should accept comparators on functions" do
		  c = @table[:name]
		  compile(c.soundex == 'test').must_be_like %{SOUNDEX("users"."name") = 'test'}
	  end
	  
	  
	  it "should accept in on select statement" do
		c = @table[:name]
		compile(c.in(@table.project(@table[:name])))
			.must_be_like %{"users"."name" IN (SELECT "users"."name" FROM "users")}
	  end	  
	  
	  it "should accept coalesce function properly even on none actual tables and attributes" do
		fake_at = Arel::Table.new('fake_table')
	    compile(fake_at['fake_attribute'].coalesce('other_value'))
			.must_be_like %{COALESCE("fake_table"."fake_attribute", 'other_value')}			
	    compile(fake_at['fake_attribute'].coalesce('other_value1','other_value2'))
			.must_be_like %{COALESCE("fake_table"."fake_attribute", 'other_value1', 'other_value2')}
        compile(fake_at['fake_attribute'].coalesce('other_value1').coalesce('other_value2'))
			.must_be_like %{COALESCE(COALESCE("fake_table"."fake_attribute", 'other_value1'), 'other_value2')}	
	    compile(fake_at['fake_attribute'].coalesce('other_value').matches('truc'))
			.must_be_like %{COALESCE("fake_table"."fake_attribute", 'other_value') LIKE 'truc'}				
		compile(fake_at['fake_attribute'].coalesce('other_value').imatches('truc'))
			.must_be_like %{COALESCE("fake_table"."fake_attribute", 'other_value') ILIKE 'truc'}				
	  end
	  
	  it "should be possible to cast nodes types" do	    
		compile(@table[:id].cast('char'))
			.must_be_like %{CAST("users"."id" AS char)}
		
		compile(@table[:id].coalesce(' ').cast('char'))
			.must_be_like %{CAST(COALESCE("users"."id", ' ') AS char)}
	
		compile(@table[:id].coalesce(' ').cast(:string))
			.must_be_like %{CAST(COALESCE("users"."id", ' ') AS char)}
			
		compile(@table[:id].cast(:string).coalesce(' '))
			.must_be_like %{COALESCE(CAST(\"users\".\"id\" AS char), ' ')}
				
		compile(@table[:id].cast('char') + ' ')
			.must_be_like %{CONCAT(CAST("users"."id" AS char), ' ')}
			
		compile(@table[:id].cast('int') + 2)
			.must_be_like %{(CAST("users"."id" AS int) + 2)}
	  end
	  	  
	  
	  it "should be possible to specify a cool format on number" do	  
		#puts @price.format_number("$$ %+030.2e €€","fr_FR").to_sql
		compile(@price.format_number("$$ %+030.2e €€","fr_FR"))
			.must_be_like %{CONCAT('$$ ', CASE \"products\".\"price\" WHEN 0 THEN 0 ELSE CONCAT('', CASE WHEN \"products\".\"price\" < 0 THEN '-' ELSE '+' END, CASE WHEN (ABS(30) - (LENGTH(CONCAT(FORMAT(ABS(\"products\".\"price\") / POW(10, FLOOR(LOG10(ABS(\"products\".\"price\")))), 2, 'fr_FR'), 'e', FORMAT(FLOOR(LOG10(ABS(\"products\".\"price\"))), 0))) + LENGTH(CASE WHEN \"products\".\"price\" < 0 THEN '-' ELSE '+' END))) > 0 THEN REPEAT('0', (ABS(30) - (LENGTH(CONCAT(FORMAT(ABS(\"products\".\"price\") / POW(10, FLOOR(LOG10(ABS(\"products\".\"price\")))), 2, 'fr_FR'), 'e', FORMAT(FLOOR(LOG10(ABS(\"products\".\"price\"))), 0))) + LENGTH(CASE WHEN \"products\".\"price\" < 0 THEN '-' ELSE '+' END)))) ELSE '' END, CONCAT(FORMAT(ABS(\"products\".\"price\") / POW(10, FLOOR(LOG10(ABS(\"products\".\"price\")))), 2, 'fr_FR'), 'e', FORMAT(FLOOR(LOG10(ABS(\"products\".\"price\"))), 0)), '') END, ' €€')}
	  end
	  
	
	  
	  puts "AREL VERSION : " + Arel::VERSION.to_s
    end
  end
end 
