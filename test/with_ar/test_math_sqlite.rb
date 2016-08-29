require 'helper'

module ArelExtensions
  module WthAr

    describe 'the sqlite visitor can do maths' do

      before do
        ActiveRecord::Base.configurations = YAML.load_file('test/database.yml')
        ActiveRecord::Base.establish_connection(ENV['DB'] || (RUBY_PLATFORM == 'java' ? :"jdbc-sqlite" : :sqlite))
        ActiveRecord::Base.default_timezone = :utc
        Arel::Table.engine = ActiveRecord::Base
        @cnx = ActiveRecord::Base.connection
        @cnx.drop_table(:users) rescue nil 
        @cnx.drop_table(:products) rescue nil 
        @cnx.create_table :users do |t|
          t.column :age, :integer
          t.column :name, :string
          t.column :comments, :text
          t.column :created_at, :date
          t.column :updated_at, :date
          t.column :score, :floor
        end
        @cnx.create_table :products do |t|
          t.column :price, :decimal
        end
        class User < ActiveRecord::Base
        end
        d = Date.new(2016, 5,23)
        User.create! :age => 5, :name => "Lucas", :created_at => d, :score => 20.16
        User.create! :age => 15, :name => "Sophie", :created_at => d, :score => 20.16
        User.create! :age => 20, :name => "Camille", :created_at => d, :score => 20.16
        User.create! :age => 21, :name => "Arthur", :created_at => d, :score => 65.62
        User.create! :age => 23, :name => "Myung", :created_at => d, :score => 20.16
        @laure = User.create :age => 25, :name => "Laure", :created_at => d, :score =>20.16
        User.create! :age => nil, :name => "Test", :created_at => d, :score => 1.62
        @neg = User.create :age => -20, :name => "Negatif", :created_at => d, :score => 0.17
        @table = Arel::Table.new(:users)
        @age = @table[:age]
      end
      after do
        @cnx.drop_table(:users)
        @cnx.drop_table(:products)
      end

      it "should do maths" do
        #ABS
        assert_equal 20, User.where(:id => @neg.id).select(@age.abs.as("res")).first.res
        assert_equal 14, User.where(:id => @laure.id).select((@age - 39).abs.as("res")).first.res

        #CEIL # require extensions

        # RAND
        assert_equal 5, User.where(User.arel_table[:score].eq(20.16)).select(User.arel_table[:id]).order(Arel.rand).take(50).count
        assert_equal 8, User.select(User.arel_table[:name]).order(Arel.rand).take(50).count
      end

    end

  end
end