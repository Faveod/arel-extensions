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
        if File.exist?("init/#{ENV['DB']}.sql")
          sql = File.read("init/#{ENV['DB']}.sql")
          @cnx.execute(sql) unless sql.blank?
        end
        @cnx.drop_table(:users) rescue nil 
        @cnx.create_table :users do |t|
          t.column :age, :integer
          t.column :name, :string
          t.column :comments, :text
          t.column :created_at, :date
          t.column :updated_at, :datetime
          t.column :score, :decimal, :precision => 20, :scale => 10
        end
        @cnx.drop_table(:products) rescue nil
        @cnx.create_table :products do |t|
          t.column :price, :decimal, :precision => 20, :scale => 10
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
        u = User.create :age => 5, :name => "Lucas", :created_at => d, :score => 20.16
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
        u = User.create :age => -42, :name => "Negatif", :comments => '1,22,3,42,2', :created_at => d, :updated_at => d.to_time, :score => 0.17
        @neg = User.where(:id => u.id)

        @age = User.arel_table[:age]
        @name = User.arel_table[:name]
        @score = User.arel_table[:score]
        @created_at = User.arel_table[:created_at]
        @comments = User.arel_table[:comments]
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
        assert_in_epsilon 42.16, t(@laure, @score + 22), 0.01
      end

      def test_abs
        assert_equal 42, t(@neg, @age.abs)
        assert_equal 14, t(@laure, (@age - 39).abs)
        assert_equal 28, t(@laure, (@age - 39).abs + (@age - 39).abs)
      end

      def test_ceil
        if !$sqlite || !$load_extension_disabled
          assert_equal 1, t(@neg, @score.ceil)
          assert_equal 63, t(@arthur, @age.ceil + 42)
        end
      end

      def test_floor
        if !$sqlite || !$load_extension_disabled
          assert_equal 0, t(@neg, @score.floor)
          assert_equal 42, t(@arthur, @score.floor - 23)
        end
      end

      def test_rand
        assert 42 != User.select(Arel.rand.as('res')).first.res
        assert 0 <= User.select(Arel.rand.abs.as('res')).first.res
        assert_equal 8, User.order(Arel.rand).limit(50).count
      end

      def test_round
        assert_equal 1, User.where(@age.round(0).eq(5.0)).count
        assert_equal 0, User.where(@age.round(-1).eq(6.0)).count
        assert_equal 66, t(@arthur, @score.round)
        assert_in_epsilon 67.6, t(@arthur, @score.round(1) + 2), 0.01
      end

      def test_sum
        assert_equal 68, User.select((@age.sum + 1).as("res")).take(50).first.res
        assert_equal 134, User.select((@age.sum + @age.sum).as("res")).take(50).first.res
        assert_equal 201, User.select(((@age * 3).sum).as("res")).take(50).first.res
        assert_equal 4009, User.select(((@age * @age).sum).as("res")).take(50).first.res
      end

      # String Functions
      def test_concat
        assert_equal 'Camille Camille', t(@camille, @name + ' ' + @name)
        assert_equal 'Laure 2', t(@laure, @name + ' ' + 2)
        if ENV['DB'] == 'postgresql'
          assert_equal "Lucas Sophie", t(User.reorder(nil).from(User.select(:name).where(:name => ['Lucas', 'Sophie']).reorder(:name).as('users')), @name.group_concat(' '))
        else
          assert_equal "Lucas Sophie", t(User.where(:name => ['Lucas', 'Sophie']).reorder(:name), @name.group_concat(' '))
        end
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

      def test_find_in_set
        if !$sqlite || !$load_extension_disabled
          assert 4, t(@neg, @comments & 2)
          assert 2, t(@neg, @comments & 6)
        end
      end

      def test_string_comparators
        assert 1, t(@neg, @name >= 'test')
        assert 1, t(@neg, @name <= @comments)
      end

      def test_regexp_not_regex
        if !$sqlite || !$load_extension_disabled
          assert_equal 1, User.where(@name =~ '^M').count
          assert_equal 6, User.where(@name !~ '^L').count
          assert_equal 1, User.where(@name =~ /^M/).count
          assert_equal 6, User.where(@name !~ /^L/).count
        end
      end

      def test_imatches
        assert_equal 1, User.where(@name.imatches('m%')).count
        assert_equal 4, User.where(@name.imatches_any(['L%', '%e'])).count
        assert_equal 6, User.where(@name.idoes_not_match('L%')).count
      end

      def test_replace
        assert_equal "LucaX", t(@lucas, @name.replace("s","X"))
        assert_equal "replace", t(@lucas, @name.replace(@name,"replace"))
      end

      def test_soundex
        if (!$sqlite || !$load_extension_disabled) && (ENV['DB'] != 'postgresql')
          assert_equal "C540", t(@camille, @name.soundex)
          assert_equal 8, User.where(@name.soundex.eq(@name.soundex)).count
        end
      end

      def test_trim
        assert_equal "Myun", t(@myung, @name.rtrim("g"))
        assert_equal "yung", t(@myung, @name.ltrim("M"))
        assert_equal "yung", t(@myung, (@name + "M").trim("M"))
        assert_equal "", t(@myung, @name.rtrim(@name))
      end

      def test_coalesce
        if ENV['DB'] == 'postgresql'
          assert_equal 100, t(@test, @age.coalesce(100))
          assert_equal "Camille", t(@camille, @name.coalesce(nil, "default"))
          assert_equal 20, t(@test, @age.coalesce(nil, 20))
        else
          assert_equal "Camille", t(@camille, @name.coalesce(nil, '20'))
          assert_equal 20, t(@test, @age.coalesce(nil, 20))
        end
      end

      def test_comparator
        assert_equal 2, User.where(@age < 6).count
        assert_equal 2, User.where(@age <= 10).count
        assert_equal 3, User.where(@age > 20).count
        assert_equal 4, User.where(@age >= 20).count
        assert_equal 1, User.where(@age > 5).where(@age < 20).count
      end

      def test_date_duration
        #Year
        assert_equal 2016, @lucas.select((User.arel_table[:created_at].year).as("res")).first.res.to_i
        assert_equal 0, User.where(@created_at.year.eq("2012")).count
        #Month
        assert_equal 5, @camille.select((User.arel_table[:created_at].month).as("res")).first.res.to_i
        assert_equal 8,User.where(User.arel_table[:created_at].month.eq("05")).count
        #Week
        assert_equal 21,User.where(User.arel_table[:name].eq("Arthur")).select((User.arel_table[:created_at].week).as("res")).first.res.to_i
        assert_equal 8,User.where(User.arel_table[:created_at].month.eq("05")).count
        #Day
        assert_equal 23,User.where(User.arel_table[:name].eq("Laure")).select((User.arel_table[:created_at].day).as("res")).first.res.to_i
        assert_equal 0,User.where(User.arel_table[:created_at].day.eq("05")).count
      end


      def test_is_null
        assert_equal "Test", User.where(@age.is_null).select(@name).first.name
      end


      def test_math_plus
        d = Date.new(1997, 6, 15)
        #Concat String
        assert_equal "SophiePhan", t(@sophie, @name + "Phan")
        assert_equal "Sophie2", t(@sophie, @name + 2)
        assert_equal "Sophie1997-06-15", t(@sophie, @name + d)
        assert_equal "Sophie15", t(@sophie, @name + @age)
        assert_equal "SophieSophie", t(@sophie, @name + @name)
        assert_equal "Sophie2016-05-23", t(@sophie, @name + @created_at)
        #concat Integer
        assert_equal 1, User.where((@age + 10).eq(33)).count
        assert_equal 1, User.where((@age + "1").eq(6)).count
        assert_equal 1, User.where((@age + @age).eq(10)).count
        #concat Date
    #    puts((User.arel_table[:created_at] + 1).as("res").to_sql.inspect)
        assert_equal "2016-05-24", t(@myung, @created_at + 1).to_date.to_s
        assert_equal "2016-05-25", t(@myung, @created_at + 2.day).to_date.to_s
      end


      def test_math_moins
        d = Date.new(2016,05,20)
        #Datediff
        assert_equal 8, User.where((User.arel_table[:created_at] - User.arel_table[:created_at]).eq(0)).count
        assert_equal 3, User.where(User.arel_table[:name].eq("Laure")).select((User.arel_table[:created_at] - d).as("res")).first.res.abs.to_i
        #Substraction
        assert_equal 0, User.where((@age - 10).eq(50)).count
        assert_equal 0, User.where((@age - "10").eq(50)).count
      end

      def test_wday
        d = Date.new(2016, 6, 26)
        assert_equal 1, t(@myung, @created_at.wday).to_i
        assert_equal 0, User.select(d.wday).as("res").first.to_i
      end

    end
  end
end