require 'arelx_test_helper'

module ArelExtensions
  module WithAr
    # `column_of` only gets a table name, so it has to find the database that
    # owns the table. These tests set up a second database with a table the
    # primary one does not have. Only the model that declares that table can
    # reach it.
    class MultiDatabaseTest < Minitest::Test
      SQLITE = (RUBY_PLATFORM == 'java' ? :'jdbc-sqlite' : :sqlite).freeze

      class SecondaryBase < ActiveRecord::Base
        self.abstract_class = true
      end

      class Amount < SecondaryBase
        self.table_name = 'amount_tests'
      end

      class Member < ActiveRecord::Base
        self.table_name = 'member_tests'
      end

      def connect_db
        ActiveRecord::Base.configurations = ConfigLoader.load('test/database.yml')
        if ENV['DB'] == 'oracle' && ((defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx') || (RUBY_PLATFORM == 'java')) # not supported
          skip "Platform not supported (DB: #{ENV['DB']}, RUBY_ENGINE: #{RUBY_ENGINE}, RUBY_PLATFORM: #{RUBY_PLATFORM})"
        end
        @env_db = ENV['DB']
        ActiveRecord::Base.establish_connection(@env_db.try(:to_sym) || SQLITE)
        @cnx = ActiveRecord::Base.connection
        Arel::Table.engine = ActiveRecord::Base
        SecondaryBase.establish_connection(SQLITE)
        @secondary_cnx = SecondaryBase.connection
      end

      def setup_db
        @cnx.drop_table(:member_tests) rescue nil
        @cnx.create_table :member_tests do |t|
          t.column :name, :string
          t.column :score, :decimal, precision: 20, scale: 10
        end
        # No model declares this table. Only the primary database has data for it.
        @cnx.drop_table(:orphan_tests) rescue nil
        @cnx.create_table :orphan_tests do |t|
          t.column :quantity, :integer
        end
        @secondary_cnx.drop_table(:amount_tests) rescue nil
        @secondary_cnx.create_table :amount_tests do |t|
          t.column :debit, :decimal, precision: 20, scale: 10
        end
      end

      def setup
        connect_db
        setup_db
      end

      def teardown
        @cnx.drop_table(:member_tests) rescue nil
        @cnx.drop_table(:orphan_tests) rescue nil
        SecondaryBase.remove_connection
      end

      # The statements that `blk` sends to the primary database.
      #
      # This only watches. If `blk` raises, the exception propagates and we lose
      # the collected statements.
      def primary_statements(&blk)
        statements = []
        primary_pool = ActiveRecord::Base.connection_pool
        subscriber =
          ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
            cnx = payload[:connection]
            statements << payload[:sql] if cnx.respond_to?(:pool) && cnx.pool == primary_pool
          end
        blk.call
        statements
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      # Every test here assumes two separate databases, each with a table the
      # other does not have.
      def test_the_two_databases_are_distinct
        refute_same ActiveRecord::Base.connection_pool, SecondaryBase.connection_pool, 'The secondary model must not share the pool of the primary'

        assert @cnx.data_source_exists?('member_tests'), 'The primary database must have its own table'
        refute @cnx.data_source_exists?('amount_tests'), 'The primary database must not have the table of the secondary database'

        assert @secondary_cnx.data_source_exists?('amount_tests'), 'The secondary database must have its own table'
        refute @secondary_cnx.data_source_exists?('member_tests'), 'The secondary database must not have the table of the primary database'
      end

      # Guards the two tests below that assert on an empty result. An empty
      # result has to mean nothing ran. It must not mean the subscriber never
      # sees anything.
      def test_primary_statements_observes_the_primary_database
        skip 'sql.active_record does not carry the connection before rails 6' if ACTIVE_RECORD_VERSION < V6

        observed = primary_statements { @cnx.select_all(Member.arel_table.project(Arel.star).to_sql) }
        assert(observed.any? { |sql| sql.include?('member_tests') }, "A statement of the primary database must be observed, got #{observed.inspect}")

        observed = primary_statements { @secondary_cnx.select_all(Amount.arel_table.project(Arel.star).to_sql) }
        assert_empty observed, 'A statement of the secondary database must not be observed'
      end

      def test_primary_statements_does_not_swallow_the_exception_of_its_block
        boom = Class.new(StandardError)

        assert_raises(boom) { primary_statements { raise(boom) } }
      end

      def test_column_of_secondary_database
        assert_equal :decimal, Arel.column_of('amount_tests', 'debit')&.type, 'A column of a table in a different database must be resolved'
        assert_nil Arel.column_of('amount_tests', 'maflavla'), 'Existent table but non-existent column should return nil'
      end

      def test_column_of_primary_database
        assert_equal :string, Arel.column_of('member_tests', 'name')&.type, 'A column of a table that a model declares must still be resolved'
        assert_equal :integer, Arel.column_of('orphan_tests', 'quantity')&.type, 'A column of a table that no model declares must still be resolved'
        assert_nil Arel.column_of('chupa', 'maflavla'), 'Non-existent table and column should return nil'
      end

      def test_column_of_does_not_touch_the_primary_database_for_a_secondary_table
        skip 'sql.active_record does not carry the connection before rails 6' if ACTIVE_RECORD_VERSION < V6

        # The primary database has no `amount_tests` table, so reflecting it
        # there fails. On postgres that also kills the surrounding transaction.
        assert_empty(primary_statements { Arel.column_of('amount_tests', 'debit') }, 'Reflecting a secondary-database table must not query the primary')
      end

      def test_model_of_finds_the_model_that_declares_a_table
        assert_equal Amount, ArelExtensions.model_of('amount_tests'), 'The model declaring the secondary table'
        assert_equal Member, ArelExtensions.model_of('member_tests'), 'The model declaring the primary table'
        assert_nil ArelExtensions.model_of('orphan_tests'), 'A table that no model declares has no model'
      end

      # `+` on a decimal is an addition, and on a string a concatenation. It
      # dispatches on the `return_type` of the function, which comes from the
      # attribute. So the column type has to travel from the model to the SQL.
      # Each assertion checks one step.
      def test_operators_dispatch_on_the_type_of_a_secondary_database_column
        attribute = Amount.arel_table[:debit]

        assert_equal :decimal, ArelExtensions.type_of(attribute), 'The type must come from the model that declares the table'
        assert_equal :decimal, attribute.coalesce(0).return_type, 'The function must take the type of its attribute'

        # `+` renders differently per adapter, so compare against the same
        # expression on a decimal column of the primary database.
        primary = (Member.arel_table[:score].coalesce(0) + Member.arel_table[:score].coalesce(0)).to_sql
        secondary = (attribute.coalesce(0) + attribute.coalesce(0)).to_sql

        assert_equal primary, secondary.gsub('amount_tests', 'member_tests').gsub('debit', 'score'), 'A secondary decimal column must render like a primary one'
      end

      # The opposite case, which is what `master` did with a secondary-database
      # column. No type means `+` concatenates. A bare `Arel::Table` has no type
      # caster, and no model declares this name, so nothing supplies a type.
      def test_an_attribute_with_no_type_concatenates
        attribute = Arel::Table.new('chupa')[:maflavla]

        assert_nil ArelExtensions.type_of(attribute), 'An attribute of an unknown table has no type'

        expected = attribute.coalesce('').concat(attribute.coalesce('')).to_sql
        assert_equal expected, (attribute.coalesce('') + attribute.coalesce('')).to_sql, 'With no type, `+` must be a concatenation'
      end
    end
  end
end
