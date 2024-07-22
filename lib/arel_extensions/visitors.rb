# MSSQL visitors for java and rails ≥ 7 are painful to work with:
# requiring the exact path to the visitor is needed even if the
# AR adapter was loaded. It's also needed exactly here because:
# 1. putting it inside the visitor or anywhere else will not
#    guarantee its actual loading.
# 2. it needs to load before arel_extensions/visitors.
if RUBY_PLATFORM == 'java' && Gem::Specification.find { |g| g.name == 'jdbc-mssql' }
  begin
    require 'arel/visitors/sqlserver'
  rescue LoadError
    warn 'arel/visitors/sqlserver not found: MSSQL might not work correctly.'
  end
end

require 'arel_extensions/visitors/convert_format'
require 'arel_extensions/visitors/to_sql'
require 'arel_extensions/visitors/mysql'
require 'arel_extensions/visitors/postgresql'
require 'arel_extensions/visitors/sqlite'

if defined?(Arel::Visitors::Oracle)
  require 'arel_extensions/visitors/oracle'
  require 'arel_extensions/visitors/oracle12'
end

if defined?(Arel::Visitors::SQLServer) || defined?(Arel::Visitors::MSSQL)
  require 'arel_extensions/visitors/mssql'
end

if defined?(Arel::Visitors::SQLServer)
  class Arel::Visitors::SQLServer
    include ArelExtensions::Visitors::MSSQL
  end
end

if defined?(Arel::Visitors::DepthFirst)
  class Arel::Visitors::DepthFirst
    def visit_Arel_SelectManager o
        visit o.ast
    end
  end
end

# Especially required here, not inside the next if, for Arel < 6.
if RUBY_PLATFORM != 'java'
  begin
    require 'arel_sqlserver'
  rescue LoadError
    warn 'gem arel_sqlserver not found: SQLServer Visitor might not work correctly.'
  end
end

if defined?(Arel::Visitors::MSSQL)
  class Arel::Visitors::MSSQL
    include ArelExtensions::Visitors::MSSQL

    alias_method(:old_visit_Arel_Nodes_As, :visit_Arel_Nodes_As) rescue nil
    def visit_Arel_Nodes_As o, collector
      if o.left.is_a?(Arel::Nodes::Binary)
        collector << '('
        collector = visit o.left, collector
        collector << ')'
      else
        collector = visit o.left, collector
      end
      collector << ' AS ['
      collector = visit o.right, collector
      collector << ']'
      collector
    end

    alias_method(:old_visit_Arel_Nodes_SelectStatement, :visit_Arel_Nodes_SelectStatement) rescue nil
    def visit_Arel_Nodes_SelectStatement o, collector
      if !collector.value.blank? && o.limit.blank? && o.offset.blank?
        o = o.dup
        o.orders = []
      end
      old_visit_Arel_Nodes_SelectStatement(o, collector)
    end
  end
end

if defined?(Arel::Visitors::SQLServer)
  if Arel::VERSION.to_i >= 6
    class Arel::Visitors::SQLServer
      include ArelExtensions::Visitors::MSSQL

      alias_method(:old_visit_Arel_Nodes_SelectStatement, :visit_Arel_Nodes_SelectStatement) rescue nil
      def visit_Arel_Nodes_SelectStatement o, collector
        if !collector.value.blank? && o.limit.blank? && o.offset.blank?
          o = o.dup
          o.orders = []
        end
        old_visit_Arel_Nodes_SelectStatement(o, collector)
      end

      alias_method(:old_visit_Arel_Nodes_As, :visit_Arel_Nodes_As) rescue nil
      def visit_Arel_Nodes_As o, collector
        if o.left.is_a?(Arel::Nodes::Binary)
          collector << '('
          collector = visit o.left, collector
          collector << ')'
        else
          collector = visit o.left, collector
        end
        collector << ' AS '
        if /\A\[.*\]\z/ !~ o.right
          collector << '['
          collector = visit o.right, collector
          collector << ']'
        else
          collector = visit o.right, collector
        end
        collector
      end

      alias_method(:old_primary_Key_From_Table, :primary_Key_From_Table) rescue nil
      def primary_Key_From_Table t
        return unless t

        column_name = @connection.schema_cache.primary_keys(t.name) ||
                      @connection.schema_cache.columns_hash(t.name).first.try(:second).try(:name)
        column_name ? t[column_name] : nil
      end
    end
  end
end
