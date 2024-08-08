# MSSQL visitors for java and rails ≥ 7 are painful to work with:
# requiring the exact path to the visitor is needed even if the
# AR adapter was loaded. It's also needed exactly here because:
# 1. putting it inside the visitor or anywhere else will not
#    guarantee its actual loading.
# 2. it needs to load before arel_extensions/visitors.
if RUBY_PLATFORM == 'java' \
  && RUBY_ENGINE == 'jruby' \
  && (version = JRUBY_VERSION.split('.').map(&:to_i)) && version[0] == 9 && version[1] >= 4 \
  && Gem::Specification.find { |g| g.name == 'jdbc-mssql' }
  begin
    require 'arel/visitors/sqlserver'
  rescue LoadError
    warn 'arel/visitors/sqlserver not found: MSSQL might not work correctly.'
  end
elsif RUBY_PLATFORM != 'java' && Arel::VERSION.to_i < 10
  begin
    require 'arel_sqlserver'
  rescue LoadError
    warn 'arel_sqlserver not found: SQLServer Visitor might not work correctly.'
  end
end

require 'arel_extensions/visitors/convert_format'
require 'arel_extensions/visitors/to_sql'
require 'arel_extensions/visitors/mysql'
require 'arel_extensions/visitors/mssql'
require 'arel_extensions/visitors/postgresql'
require 'arel_extensions/visitors/sqlite'

if defined?(Arel::Visitors::Oracle)
  require 'arel_extensions/visitors/oracle'
  require 'arel_extensions/visitors/oracle12'
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

if defined?(Arel::Visitors::MSSQL)
  class Arel::Visitors::MSSQL
    include ArelExtensions::Visitors::MSSQL

    alias_method(:old_visit_Arel_Nodes_SelectStatement, :visit_Arel_Nodes_SelectStatement)
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
  class Arel::Visitors::SQLServer
    include ArelExtensions::Visitors::MSSQL

    # There's a bug when working with jruby 9.4 that prevents us from
    # refactoring this and putting it in the main module, or even in a separate
    # module then including it.
    #
    # Reason: the line in this file that does:
    #
    #   require 'arel_extensions/visitors/mssql'
    #
    # The error could be seen by:
    #
    #   1. placing the visit_ inside the visitor, or placing it in a module
    #      then including it here.
    #   2. replacing the `rescue nil` from aliasing trick, and printing the
    #      error.
    #
    # It complains that the visit_ does not exist in the module, as if it's
    # evaluating the module eagerly, instead of lazily like in other versions
    # of ruby.
    #
    # It might be something different, but this is the first thing we should
    # investigate.

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
