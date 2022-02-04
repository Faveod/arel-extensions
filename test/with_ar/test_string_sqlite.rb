require 'arelx_test_helper'
require 'date'

module ArelExtensions
  module WithAr
    describe 'the sqlite visitor can do string operations' do
      before do
        ActiveRecord::Base.configurations = YAML.load_file('test/database.yml')
        ActiveRecord::Base.establish_connection(ENV['DB'] || (RUBY_PLATFORM == 'java' ? :"jdbc-sqlite" : :sqlite))
        if ActiveRecord::VERSION::MAJOR >= 7
          ActiveRecord.default_timezone = :utc
        else
          ActiveRecord::Base.default_timezone = :utc
        end
        @cnx = ActiveRecord::Base.connection
        Arel::Table.engine = ActiveRecord::Base
        @cnx.drop_table(:users) rescue nil
        @cnx.create_table :users do |t|
          t.column :age, :integer
          t.column :name, :string
          t.column :comments, :text
          t.column :created_at, :date
          t.column :updated_at, :date
          t.column :score, :decimal
        end
        @cnx.create_table :products do |t|
          t.column :price, :decimal
        end
        class User < ActiveRecord::Base
        end
        d = Date.new(2016, 5,23)
        @lucas = User.create! :age => 5, :name => "Lucas", :created_at => d, :score => 20.16
        sophie = User.create :age => 15, :name => "Sophie", :created_at => d, :score => 20.16
        @sophie = User.where(:id => sophie.id)
        User.create! :age => 20, :name => "Camille", :created_at => d, :score => 20.16
        User.create! :age => 21, :name => "Arthur", :created_at => d, :score => 65.62
        User.create! :age => 23, :name => "Myung", :created_at => d, :score => 20.16
        @laure = User.create :age => 25, :name => "Laure", :created_at => d, :score =>20.16
        User.create! :age => nil, :name => "Test", :created_at => d, :score => 1.62
        @neg = User.create :age => -20, :name => "Negatif", :created_at => d, :score => 0.17
        @table = Arel::Table.new(:users)
        @name = @table[:name]
      end
      after do
        @cnx.drop_table(:users)
      end

      it "should do string operations" do
        # concat
        d = Date.new(1997, 6, 15)
        assert_equal "SophiePhan", @sophie.select((@name + "Phan").as("res")).first.res
        assert_equal "Sophie2", @sophie.select((@name + 2).as("res")).first.res
        assert_equal "Sophie1997-06-15", @sophie.select((@name + d).as("res")).first.res
        assert_equal "Sophie15", @sophie.select((User.arel_table[:name] + User.arel_table[:age]).as("res")).first.res
        assert_equal "SophieSophie", @sophie.select((User.arel_table[:name] + User.arel_table[:name]).as("res")).first.res
        assert_equal "Sophie2016-05-23", @sophie.select((User.arel_table[:name] + User.arel_table[:created_at]).as("res")).first.res
        # concat Integer
        assert_equal 1, User.where((User.arel_table[:age] + 10).eq(33)).count
        assert_equal 1, User.where((User.arel_table[:age] + "1").eq(6)).count
        assert_equal 1, User.where((User.arel_table[:age] + User.arel_table[:age]).eq(10)).count

        # Replace
        assert_equal "LucaX", User.where(:id => @lucas).select(@name.replace("s","X").as("res")).first.res
        assert_equal "replace", User.where(:id => @lucas).select(@name.replace(@name,"replace").as("res")).first.res
      end
    end
  end
end
