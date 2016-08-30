require 'helper'
require 'date'

module ArelExtensions
  module WthAr

    class ListTest < Minitest::Test
      def setup_db
        ActiveRecord::Base.configurations = YAML.load_file('test/database.yml')
        ActiveRecord::Base.establish_connection(ENV['DB'].try(:to_sym) || (RUBY_PLATFORM == 'java' ? :"jdbc-sqlite" : :sqlite))
        ActiveRecord::Base.default_timezone = :utc
        @cnx = ActiveRecord::Base.connection
        $sqlite ||= false
        if ActiveRecord::Base.connection.adapter_name =~ /sqlite/i
          $sqlite = true
          db = @cnx.raw_connection
          $load_extension_disabled ||= false
          if !$load_extension_disabled
            begin
              db.create_function("find_in_set", 1) do |func, value1, value2|
                func.result = value1.index(value2)
              end
              db.enable_load_extension(1)
              db.load_extension("/usr/lib/sqlite3/pcre.so")
              db.load_extension("/usr/lib/sqlite3/extension-functions.so")
              db.enable_load_extension(0)
              #function find_in_set
            rescue => e
              $load_extension_disabled = true
              puts "can not load extensions #{e.inspect}"
            end
          end
        end
        @cnx.drop_table(:users) rescue nil 
        @cnx.create_table :users do |t|
          t.column :age, :integer
          t.column :name, :string
          t.column :comments, :text
          t.column :created_at, :date
          t.column :updated_at, :datetime
          t.column :score, :decimal
        end
        @cnx.create_table :products do |t|
          t.column :price, :decimal
        end
      end

      def teardown_db
        @cnx.drop_table(:users)
        @cnx.drop_table(:products)
      end

      class User < ActiveRecord::Base
      end
      class Product < ActiveRecord::Base
      end


      def setup
        d = Date.new(2016,05,23)
        setup_db
        u = User.create :age => 5, :name => "Lucas", :created_at => d , :score => 20.16
        @lucas = User.where(:id => u.id)
        u = User.create :age => 15, :name => "Sophie", :created_at => d, :score => 20.16
        @sophie = User.where(:id => u.id)
        u = User.create :age => 20, :name => "Camille", :created_at => d, :score => 20.16
        @camille = User.where(:id => u.id)
        u = User.create :age => 21, :name => "Arthur", :created_at => d, :score => 65.62
        @arthur = User.where(:id => u.id)
        u = User.create :age => 23, :name => "Myung", :created_at => d, :score => 20.16
        @myung = User.where(:id => u.id)
        u = User.create :age => 25, :name => "Laure", :created_at => d, :score => 20.16
        @laure = User.where(:id => u.id)
        u = User.create :age => nil, :name => "Test", :created_at => d, :score => 1.62
        @test = User.where(:id => u.id)
        u = User.create :age => -42, :name => "Negatif", :comments => '1,2,3', :created_at => d, :updated_at => d.to_time, :score => 0.17
        @neg = User.where(:id => u.id)

        @age = User.arel_table[:age]
        @name = User.arel_table[:name]
        @score = User.arel_table[:score]
        @price = Product.arel_table[:price]
      end

      def teardown
        teardown_db
      end

      def t(scope, node)
        scope.select(node.as('res')).first.res
      end

      # Math Functions
      def test_classical_arel
        assert_equal 42.16, t(@laure, @score + 22)
      end

      def test_abs
        assert_equal 42, t(@neg, @age.abs)
        assert_equal 14, t(@laure, (@age - 39).abs)
        assert_equal 28, t(@laure, (@age - 39).abs + (@age - 39).abs)
      end

      def test_ceil
        if !$sqlite || !$load_extension_disabled
          assert_equal 1, @neg.select((User.arel_table[:score].ceil).as("res")).first.res
          assert_equal 108, @arthur.select((User.arel_table[:score].ceil + 42).as("res")).first.res
        end
      end

      def test_floor
        if !$sqlite || !$load_extension_disabled
          assert_equal 0, t(@neg, @score.floor)
          assert_equal 42, t(@arthur, @score.floor - 23)
        end
      end

      def test_ceil_floor
        if !$sqlite || !$load_extension_disabled
          assert_equal 1, @neg.select((User.arel_table[:score].ceil).as("res")).first.res
          assert_equal 108, @arthur.select((User.arel_table[:score].ceil + 42).as("res")).first.res
        end
      end

      def test_rand
        assert 42 != User.select(Arel.rand.as('res')).first.res
        assert 0 <= User.select(Arel.rand.abs.as('res')).first.res
        assert_equal 8, User.order(Arel.rand).limit(50).count
      end

      def test_round
        assert_equal 1, User.where(((User.arel_table[:age]).round(0)).eq(5.0)).count
        assert_equal 0, User.where(((User.arel_table[:age]).round(-1)).eq(6.0)).count
        assert_equal 66, t(@arthur, @score.round)
        assert_equal 67.6, t(@arthur, @score.round(1) + 2)
      end

      def test_sum
        assert_equal 68, User.select((@age.sum + 1).as("res")).take(50).first.res
        assert_equal 134, User.select((@age.sum + User.arel_table[:age].sum).as("res")).take(50).first.res
        assert_equal 201, User.select(((@age * 3).sum).as("res")).take(50).first.res
        assert_equal 4009, User.select(((@age * @age).sum).as("res")).take(50).first.res
      end

      # String Functions
      def test_concat
        assert_equal 'Camille Camille', t(@camille, @name + ' ' + @name)
        assert_equal 'Laure 2', t(@laure, @name + ' ' + 2)
      end

      def test_length
        assert_equal 7, t(@camille, @name.length)
        assert_equal 7, t(@camille, @name.length.round.abs)
        assert_equal 42, t(@laure, @name.length + 37)
      end

      def test_locate
        if !$sqlite || !$load_extension_disabled
          assert_equal 1, t(@camille, @name.locate("C"))
          assert_equal 0, t(@lucas, @name.locate("z"))
          assert_equal 5, t(@lucas, @name.locate("s"))
        end
      end


      def test_findinset
        if !$sqlite || !$load_extension_disabled
          db = ActiveRecord::Base.connection.raw_connection
          assert_equal 3, db.get_first_value( "select find_in_set(name,'i') from users where name = 'Camille'" )
          assert_equal "",db.get_first_value( "select find_in_set(name,'p') from users where name = 'Camille'" ).to_s
        end
        #number
        #assert_equal 1,User.select(User.arel_table[:name] & ("l")).count
        #assert_equal 3,(User.select(User.arel_table[:age] & [5,15,20]))
        #string
      end

      def test_string_functions

      end

if false
      it "should accept functions on strings" do
        c = @table[:name]
        compile(c.locate('test')).must_be_like %{LOCATE("users"."name", 'test')}
        compile(c & 42).must_be_like %{FIND_IN_SET(42, "users"."name")}

        compile((c >= 'test').as('new_name')).must_be_like %{("users"."name" >= 'test') AS new_name}
        compile(c <= @table[:comments]).must_be_like %{"users"."name" <= "users"."comments"}
        compile(c =~ /\Atest\Z/).must_be_like %{"users"."name" REGEXP '^test$'}
        compile(c !~ /\Ate\Dst\Z/).must_be_like %{"users"."name" NOT REGEXP '^te[^0-9]st$'}
        compile(c.imatches('%test%')).must_be_like %{"users"."name" ILIKE '%test%'}
        compile(c.imatches_any(['%test%', 't2'])).must_be_like %{("users"."name" ILIKE '%test%' OR "users"."name" ILIKE 't2')}
        compile(c.idoes_not_match('%test%')).must_be_like %{"users"."name" NOT ILIKE '%test%'}
      end
end

      def test_coalesce
        if @cnx.adapter_name =~ /pgsql/i
            assert_equal 100,User.where(User.arel_table[:name].eq("Test")).select((User.arel_table[:age].coalesce(100)).as("res")).first.res
            assert_equal "Camille",User.where(User.arel_table[:name].eq("Camille")).select((User.arel_table[:name].coalesce("Null","default")).as("res")).first.res
        else
          assert_equal "Camille",User.where(User.arel_table[:name].eq("Camille")).select((User.arel_table[:name].coalesce("Null",20)).as("res")).first.res
          assert_equal 20,User.where(User.arel_table[:name].eq("Test")).select((User.arel_table[:age].coalesce(nil,20)).as("res")).first.res
        end
      end

      def test_Comparator
        assert_equal 2,User.where(User.arel_table[:age] < 6 ).count
        assert_equal 2,User.where(User.arel_table[:age] <=10 ).count
        assert_equal 3,User.where(User.arel_table[:age] > 20 ).count
        assert_equal 4,User.where(User.arel_table[:age] >=20 ).count
        assert_equal 1,User.where(User.arel_table[:age] > 5 ).where(User.arel_table[:age] < 20 ).count
      end

      def test_date_duration
        #Year
        assert_equal 2016,User.where(User.arel_table[:name].eq("Lucas")).select((User.arel_table[:created_at].year).as("res")).first.res.to_i
        assert_equal 0,User.where(User.arel_table[:created_at].year.eq("2012")).count
        #Month
        assert_equal 5,User.where(User.arel_table[:name].eq("Camille")).select((User.arel_table[:created_at].month).as("res")).first.res.to_i
        assert_equal 8,User.where(User.arel_table[:created_at].month.eq("05")).count
        #Week
        assert_equal 21,User.where(User.arel_table[:name].eq("Arthur")).select((User.arel_table[:created_at].week).as("res")).first.res.to_i
        assert_equal 8,User.where(User.arel_table[:created_at].month.eq("05")).count
        #Day
        assert_equal 23,User.where(User.arel_table[:name].eq("Laure")).select((User.arel_table[:created_at].day).as("res")).first.res.to_i
        assert_equal 0,User.where(User.arel_table[:created_at].day.eq("05")).count
      end







      def test_isnull
        if ActiveRecord::Base.connection.adapter_name =~ /pgsql/i
          assert_equal 100,User.where(User.arel_table[:name].eq("Test")).select((User.arel_table[:age].isnull(100)).as("res")).first.res
        else
          assert_equal "default",User.where(User.arel_table[:name].eq("Test")).select((User.arel_table[:age].isnull('default')).as("res")).first.res
          assert_equal "Test",User.where((User.arel_table[:age].isnull('default')).eq('default')).select(User.arel_table[:name]).first.name.to_s
        end
      end






      def test_math_plus
        d = Date.new(1997,06,15)
        #Concat String
        assert_equal "SophiePhan",User.where(User.arel_table[:name].eq("Sophie")).select((User.arel_table[:name] + "Phan").as("res")).first.res
        assert_equal "Sophie2",User.where(User.arel_table[:name].eq("Sophie")).select((User.arel_table[:name] + 2 ).as("res")).first.res
        assert_equal "Sophie1997-06-15",User.where(User.arel_table[:name].eq("Sophie")).select((User.arel_table[:name] + d).as("res")).first.res
        assert_equal "Sophie15",User.where(User.arel_table[:name].eq("Sophie")).select((User.arel_table[:name] + User.arel_table[:age]).as("res")).first.res
        assert_equal "SophieSophie",User.where(User.arel_table[:name].eq("Sophie")).select((User.arel_table[:name] + User.arel_table[:name]).as("res")).first.res
        assert_equal "Sophie2016-05-23",User.where(User.arel_table[:name].eq("Sophie")).select((User.arel_table[:name] + User.arel_table[:created_at]).as("res")).first.res
        #concat Integer
        assert_equal 1, User.where((User.arel_table[:age] + 10).eq(33)).count
        assert_equal 1, User.where((User.arel_table[:age] + "1").eq(6)).count
        assert_equal 1, User.where((User.arel_table[:age] + User.arel_table[:age]).eq(10)).count
        #concat Date
    #    puts((User.arel_table[:created_at] + 1).as("res").to_sql.inspect)
        assert_equal "2016-05-24", @myung.select((User.arel_table[:created_at] + 1).as("res")).first.res.to_date.to_s
        assert_equal "2016-05-25", @myung.select((User.arel_table[:created_at] + 2.day).as("res")).first.res.to_date.to_s
      end


      def test_math_moins
        d = Date.new(2016,05,20)
        #Datediff
        assert_equal 8,User.where((User.arel_table[:created_at] - User.arel_table[:created_at]).eq(0)).count
        assert_equal 3,User.where(User.arel_table[:name].eq("Laure")).select((User.arel_table[:created_at] - d).as("res")).first.res.abs.to_i
        #Substraction
        assert_equal 0, User.where((User.arel_table[:age] - 10).eq(50)).count
        assert_equal 0, User.where((User.arel_table[:age] - "10").eq(50)).count
      end




      def test_regexp_not_regex
        if !$sqlite || !$load_extension_disabled
          assert_equal 1, User.where(User.arel_table[:name] =~ '^M').count
          assert_equal 6, User.where(User.arel_table[:name] != '^L').count
        end
      end

      def test_replace
        assert_equal "LucaX",User.where(User.arel_table[:name].eq("Lucas")).select(((User.arel_table[:name]).replace("s","X")).as("res")).first.res
        assert_equal "replace",User.where(User.arel_table[:name].eq("Lucas")).select(((User.arel_table[:name]).replace(User.arel_table[:name],"replace")).as("res")).first.res
      end





      def test_Soundex
        if !$sqlite || !$load_extension_disabled
          assert_equal "C540",User.where(User.arel_table[:name].eq("Camille")).select((User.arel_table[:name].soundex).as("res")).first.res.to_s
          assert_equal 8,User.where((User.arel_table[:name].soundex).eq(User.arel_table[:name].soundex)).count
        end
      end




      def test_trim
        assert_equal "Myun",User.where(User.arel_table[:name].eq("Myung")).select(User.arel_table[:name].rtrim("g").as("res")).first.res
        assert_equal "yung",User.where(User.arel_table[:name].eq("Myung")).select(User.arel_table[:name].ltrim("M").as("res")).first.res
        assert_equal "yung",User.where(User.arel_table[:name].eq("Myung")).select((User.arel_table[:name] + "M").trim("M").as("res")).first.res
        assert_equal "",User.where(User.arel_table[:name].eq("Myung")).select(User.arel_table[:name].rtrim(User.arel_table[:name]).as("res")).first.res

      end

      def test_wday
          d = Date.new(2016,06,26)
          assert_equal 1,User.where(User.arel_table[:name].eq("Myung")).select((User.arel_table[:created_at].wday).as("res")).first.res.to_i
          assert_equal 0,User.select(d.wday).as("res").first.to_i
      end

    end
  end
end