require 'rubygems'
require 'minitest/autorun'
require 'active_record'

$:.unshift "#{File.dirname(__FILE__)}../../lib"
require 'arel_extensions'

def setup_db
  ActiveRecord::Base.configurations = YAML.load_file('test/database.yml')
  ActiveRecord::Base.establish_connection(ENV['DB'].try(:to_sym) || (RUBY_PLATFORM == 'java' ? :"jdbc-sqlite" : :sqlite))
  if ActiveRecord::VERSION::MAJOR >= 7
    ActiveRecord.default_timezone = :utc
  else
    ActiveRecord::Base.default_timezone = :utc
  end
  @cnx = ActiveRecord::Base.connection
  if /sqlite/i.match?(ActiveRecord::Base.connection.adapter_name)
    $sqlite = true
    db = @cnx.raw_connection
    if !$load_extension_disabled
      begin
        db.enable_load_extension(1)
        db.load_extension('/usr/lib/sqlite3/pcre.so')
        db.load_extension('/usr/lib/sqlite3/extension-functions.so')
        db.enable_load_extension(0)
      rescue => e
        $load_extension_disabled = true
        $stderr << "cannot load extensions #{e.inspect}\n"
      end
    end
    # function find_in_set
    db.create_function('find_in_set', 1) do |func, value1, value2|
      func.result = value1.index(value2)
    end
  end
  @cnx.drop_table(:users) rescue nil
  @cnx.create_table :users do |t|
    t.column :age, :integer
      t.column :name, :string
      t.column :created_at, :date
      t.column :updated_at, :date
      t.column :score, :decimal
      t.column :updated_at, :datetime
  end
end

def teardown_db
  @cnx.drop_table(:users)
end

class User < ActiveRecord::Base
end

class ListTest < Minitest::Test
  def setup
    d = Date.new(2016, 05, 23)
    dt = Time.new(2016, 05, 23, 12, 34, 56)
    setup_db
    User.create age: 5, name: 'Lucas', created_at: d, score: 20.16
    User.create age: 15, name: 'Sophie', created_at: d, score: 20.16
    User.create age: 20, name: 'Camille', created_at: d, score: 20.16
    User.create age: 21, name: 'Arthur', created_at: d, score: 65.62, updated_at: dt
    u = User.create age: 23, name: 'Myung', created_at: d, score: 20.16
    @myung = User.where(id: u.id)
    User.create age: 25, name: 'Laure', created_at: d, score: 20.16
    User.create age: nil, name: 'Test', created_at: d, score: 1.62
    User.create age: -0, name: 'Negatif', created_at: d, score: 0.17
  end

  def teardown
    teardown_db
  end

  def test_abs
    assert_equal 0, User.where(User.arel_table[:name].eq('Negatif')).select(User.arel_table[:age].abs.as('res')).first.res
    assert_equal 14, User.where(User.arel_table[:name].eq('Laure')).select((User.arel_table[:age] - 39).abs.as('res')).first.res
  end

  def test_ceil
    if !$sqlite || !$load_extension_disabled
      assert_equal 1, User.where(User.arel_table[:name].eq('Negatif')).select(User.arel_table[:score].ceil.as('res')).first.res
      assert_equal 66, User.where(User.arel_table[:name].eq('Arthur')).select(User.arel_table[:score].ceil.as('res')).first.res
    end
  end

  def test_coalesce
    if /pgsql/i.match?(@cnx.adapter_name)
      assert_equal 100, User.where(User.arel_table[:name].eq('Test')).select(User.arel_table[:age].coalesce(100).as('res')).first.res
        assert_equal 'Camille', User.where(User.arel_table[:name].eq('Camille')).select(User.arel_table[:name].coalesce('Null', 'default').as('res')).first.res
    else
      assert_equal 'Camille', User.where(User.arel_table[:name].eq('Camille')).select(User.arel_table[:name].coalesce('Null', 20).as('res')).first.res
      assert_equal 20, User.where(User.arel_table[:name].eq('Test')).select(User.arel_table[:age].coalesce(nil, 20).as('res')).first.res
    end
  end

  def test_comparator
    assert_equal 2, User.where(User.arel_table[:age] < 6).count
    assert_equal 2, User.where(User.arel_table[:age] <= 10).count
    assert_equal 3, User.where(User.arel_table[:age] > 20).count
    assert_equal 4, User.where(User.arel_table[:age] >= 20).count
    assert_equal 1, User.where(User.arel_table[:age] > 5).where(User.arel_table[:age] < 20).count
  end

  def test_date_date_comparator
    d = Date.new(2016, 05, 24) #after created_at in db
    assert_equal 8, User.where(User.arel_table[:age] < d).count
    assert_equal 0, User.where(User.arel_table[:age] > d).count
    assert_equal 0, User.where(User.arel_table[:age] == d).count
    d = Date.new(2016, 05, 23)
    assert_equal 8, User.where(User.arel_table[:age] == d).count
    dt = Time.new(2016, 05, 23, 12, 35, 00) #after updated_at in db
    assert_equal 1, User.where(User.arel_table[:update_at] < dt).count
    assert_equal 0, User.where(User.arel_table[:update_at] > dt).count
  end

  def test_date_duration
    # Year
    assert_equal 2016, User.where(User.arel_table[:name].eq('Lucas')).select(User.arel_table[:created_at].year.as('res')).first.res.to_i
    assert_equal 0, User.where(User.arel_table[:created_at].year.eq('2012')).count
    # Month
    assert_equal 5, User.where(User.arel_table[:name].eq('Camille')).select(User.arel_table[:created_at].month.as('res')).first.res.to_i
    assert_equal 8, User.where(User.arel_table[:created_at].month.eq('05')).count
    # Week
    assert_equal 21, User.where(User.arel_table[:name].eq('Arthur')).select(User.arel_table[:created_at].week.as('res')).first.res.to_i
    assert_equal 8, User.where(User.arel_table[:created_at].month.eq('05')).count
    # Day
    assert_equal 23, User.where(User.arel_table[:name].eq('Laure')).select(User.arel_table[:created_at].day.as('res')).first.res.to_i
    assert_equal 0, User.where(User.arel_table[:created_at].day.eq('05')).count
  end

  def test_length
    assert_equal 7, User.where(User.arel_table[:name].eq('Camille')).select(User.arel_table[:name].length.as('res')).first.res
    assert_equal 5, User.where(User.arel_table[:name].eq('Laure')).select(User.arel_table[:name].length.as('res')).first.res
  end

  def test_locate
    if !$sqlite || !$load_extension_disabled
      assert_equal 1, User.where(User.arel_table[:name].eq('Camille')).select(User.arel_table[:name].locate('C').as('res')).first.res
      assert_equal 0, User.where(User.arel_table[:name].eq('Lucas')).select(User.arel_table[:name].locate('z').as('res')).first.res
      assert_equal 5, User.where(User.arel_table[:name].eq('Lucas')).select(User.arel_table[:name].locate('s').as('res')).first.res
    end
  end

  def test_isnull
    if /pgsql/i.match?(ActiveRecord::Base.connection.adapter_name)
      assert_equal 100, User.where(User.arel_table[:name].eq('Test')).select(User.arel_table[:age].isnull(100).as('res')).first.res
    else
      assert_equal 'default', User.where(User.arel_table[:name].eq('Test')).select(User.arel_table[:age].isnull('default').as('res')).first.res
      assert_equal 'Test', User.where(User.arel_table[:age].isnull('default').eq('default')).select(User.arel_table[:name]).first.name.to_s
    end
  end

  def test_floor
    if !$sqlite || !$load_extension_disabled
      assert_equal 0, User.where(User.arel_table[:name].eq('Negatif')).select(User.arel_table[:score].floor.as('res')).first.res
      assert_equal 65, User.where(User.arel_table[:name].eq('Arthur')).select(User.arel_table[:score].floor.as('res')).first.res
    end
  end

  def test_findinset
    db = ActiveRecord::Base.connection.raw_connection
    assert_equal 3, db.get_first_value("select find_in_set(name,'i') from users where name = 'Camille'")
    assert_equal '', db.get_first_value("select find_in_set(name,'p') from users where name = 'Camille'").to_s
    # number
    # assert_equal 1,User.select(User.arel_table[:name] & ("l")).count
    # assert_equal 3,(User.select(User.arel_table[:age] & [5,15,20]))
    # string
  end

  def test_math_plus
    d = Date.new(1997, 06, 15)
    # Concat String
    assert_equal 'SophiePhan', User.where(User.arel_table[:name].eq('Sophie')).select((User.arel_table[:name] + 'Phan').as('res')).first.res
    assert_equal 'Sophie2', User.where(User.arel_table[:name].eq('Sophie')).select((User.arel_table[:name] + 2).as('res')).first.res
    assert_equal 'Sophie1997-06-15', User.where(User.arel_table[:name].eq('Sophie')).select((User.arel_table[:name] + d).as('res')).first.res
    assert_equal 'Sophie15', User.where(User.arel_table[:name].eq('Sophie')).select((User.arel_table[:name] + User.arel_table[:age]).as('res')).first.res
    assert_equal 'SophieSophie', User.where(User.arel_table[:name].eq('Sophie')).select((User.arel_table[:name] + User.arel_table[:name]).as('res')).first.res
    assert_equal 'Sophie2016-05-23', User.where(User.arel_table[:name].eq('Sophie')).select((User.arel_table[:name] + User.arel_table[:created_at]).as('res')).first.res
    # concat Integer
    assert_equal 1, User.where((User.arel_table[:age] + 10).eq(33)).count
    assert_equal 1, User.where((User.arel_table[:age] + '1').eq(6)).count
    assert_equal 1, User.where((User.arel_table[:age] + User.arel_table[:age]).eq(10)).count
    # concat Date
    #    puts((User.arel_table[:created_at] + 1).as("res").to_sql.inspect)
    assert_equal '2016-05-24', @myung.select((User.arel_table[:created_at] + 1).as('res')).first.res.to_date.to_s
    assert_equal '2016-05-25', @myung.select((User.arel_table[:created_at] + 2.day).as('res')).first.res.to_date.to_s
  end

  def test_math_moins
    d = Date.new(2016, 05, 20)
    # Datediff
    assert_equal 8, User.where((User.arel_table[:created_at] - User.arel_table[:created_at]).eq(0)).count
    assert_equal 3, User.where(User.arel_table[:name].eq('Laure')).select((User.arel_table[:created_at] - d).as('res')).first.res.abs.to_i
    # Substraction
    assert_equal 0, User.where((User.arel_table[:age] - 10).eq(50)).count
    assert_equal 0, User.where((User.arel_table[:age] - '10').eq(50)).count
  end

  def test_rand
    assert_equal 5, User.where(User.arel_table[:score].eq(20.16)).select(User.arel_table[:id]).order(Arel.rand).take(50).count
    # test_alias  :random  :rand
    assert_equal 8, User.select(User.arel_table[:name]).order(Arel.rand).take(50).count
  end

  def test_regexp_not_regex
    if !$sqlite || !$load_extension_disabled
      assert_equal 1, User.where(User.arel_table[:name] =~ '^M').count
      assert_equal 6, User.where(User.arel_table[:name] != '^L').count
    end
  end

  def test_replace
    assert_equal 'LucaX', User.where(User.arel_table[:name].eq('Lucas')).select(User.arel_table[:name].replace('s', 'X').as('res')).first.res
    assert_equal 'replace', User.where(User.arel_table[:name].eq('Lucas')).select(User.arel_table[:name].replace(User.arel_table[:name], 'replace').as('res')).first.res
  end

  def test_round
    assert_equal 1, User.where(User.arel_table[:age].round(0).eq(5.0)).count
    assert_equal 0, User.where(User.arel_table[:age].round(-1).eq(6.0)).count
  end

  def test_Soundex
    if !$sqlite || !$load_extension_disabled
      assert_equal 'C540', User.where(User.arel_table[:name].eq('Camille')).select(User.arel_table[:name].soundex.as('res')).first.res.to_s
      assert_equal 8, User.where(User.arel_table[:name].soundex.eq(User.arel_table[:name].soundex)).count
    end
  end

  def test_Sum
    # .take(50) because of limit by ORDER BY
    assert_equal 110, User.select((User.arel_table[:age].sum + 1).as('res')).take(50).first.res
    assert_equal 218, User.select((User.arel_table[:age].sum + User.arel_table[:age].sum).as('res')).take(50).first.res
    assert_equal 327, User.select((User.arel_table[:age] * 3).sum.as('res')).take(50).first.res
    assert_equal 2245, User.select((User.arel_table[:age] * User.arel_table[:age]).sum.as('res')).take(50).first.res
  end

  def test_trim
    assert_equal 'Myun', User.where(User.arel_table[:name].eq('Myung')).select(User.arel_table[:name].rtrim('g').as('res')).first.res
    assert_equal 'yung', User.where(User.arel_table[:name].eq('Myung')).select(User.arel_table[:name].ltrim('M').as('res')).first.res
    assert_equal 'yung', User.where(User.arel_table[:name].eq('Myung')).select((User.arel_table[:name] + 'M').trim('M').as('res')).first.res
    assert_equal '', User.where(User.arel_table[:name].eq('Myung')).select(User.arel_table[:name].rtrim(User.arel_table[:name]).as('res')).first.res

  end

  def test_wday
    d = Date.new(2016, 06, 26)
      assert_equal 1, User.where(User.arel_table[:name].eq('Myung')).select(User.arel_table[:created_at].wday.as('res')).first.res.to_i
      assert_equal 0, User.select(d.wday).as('res').first.to_i
  end
end
