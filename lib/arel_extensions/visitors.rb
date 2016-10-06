require 'arel_extensions/visitors/to_sql'
require 'arel_extensions/visitors/mysql'
require 'arel_extensions/visitors/oracle'
require 'arel_extensions/visitors/postgresql'
require 'arel_extensions/visitors/sqlite'
require 'arel_extensions/visitors/mssql'



Arel::Visitors::MSSQL.class_eval do
  include ArelExtensions::Visitors::MSSQL
end

puts "VISITORS: " + Arel::Visitors::VISITORS.inspect

if Arel::Visitors::VISITORS['sqlserver']
	Arel::Visitors::VISITORS['sqlserver'].class_eval do
  		include ArelExtensions::Visitors::MSSQL
	end 
end

puts "SQLServer" if defined?(Arel::Visitors::SQLServer)