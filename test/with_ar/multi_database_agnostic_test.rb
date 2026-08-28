require 'arelx_test_helper'

module ArelExtensions
  module WithAr
    # `column_of` gets only the name of a table. Thus it must find the database
    # that owns that table. These tests make a second database. That database
    # has a table that the primary database does not have. Only the model that
    # declares the table connects to the second database.
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
        # An in-memory sqlite database is always a different database than
        # the primary database.
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

      # The SQL statements that `blk` sends to the primary database.
      def primary_statements(&blk)
        statements = []
        subscriber =
          ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
            statements << payload[:sql] if payload[:connection]&.pool == ActiveRecord::Base.connection_pool
          end
        blk.call
        statements
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
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

        # The primary database has no `amount_tests` table. Thus a reflection
        # on the primary database fails. On postgres, the failed statement also
        # stops the transaction. Then all the statements after it fail.
        assert_empty(primary_statements { Arel.column_of('amount_tests', 'debit') })
      end

      def test_operators_dispatch_on_the_type_of_a_secondary_database_column
        # If the type is not available, arel_extensions uses the string type.
        # Then it makes `+` into a concatenation. A function asks for the type.
        # An attribute has its own type caster.
        primary = (Member.arel_table[:score].coalesce(0) + Member.arel_table[:score].coalesce(0)).to_sql
        secondary = (Amount.arel_table[:debit].coalesce(0) + Amount.arel_table[:debit].coalesce(0)).to_sql

        assert_equal primary, secondary.gsub('amount_tests', 'member_tests').gsub('debit', 'score')
      end
    end
  end
end
