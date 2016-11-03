require 'arel_extensions/visitors/to_sql'
require 'arel_extensions/visitors/mysql'
require 'arel_extensions/visitors/oracle'
require 'arel_extensions/visitors/postgresql'
require 'arel_extensions/visitors/sqlite'
require 'arel_extensions/visitors/mssql'

Arel::Visitors::MSSQL.class_eval do
	include ArelExtensions::Visitors::MSSQL
end

puts "[SQL_SERVER_LOADING_DEBUG] VISITORS: " + Arel::Visitors::VISITORS.inspect

if Arel::Visitors::VISITORS['sqlserver'] && Arel::Visitors::VISITORS['sqlserver'] != Arel::Visitors::MSSQL
	Arel::Visitors::VISITORS['sqlserver'].class_eval do
  		include ArelExtensions::Visitors::MSSQL
	end 
end

puts "[SQL_SERVER_LOADING_DEBUG] Arel::Visitors constants: #{Arel::Visitors.constants.inspect}"
puts "[SQL_SERVER_LOADING_DEBUG] Arel::Visitors::ENGINE_VISITORS constants: #{Arel::Visitors::ENGINE_VISITORS.inspect}"

puts "ActiveRecord::ConnectionAdapters::SQLServerAdapter loaded #{ActiveRecord::ConnectionAdapters::SQLServerAdapter}" rescue "no ActiveRecord::ConnectionAdapters::SQLServerAdapter"
puts("[SQL_SERVER_LOADING_DEBUG] Arel::Visitors::SQLServer constants: #{Arel::Visitors::SQLServer.inspect}") rescue puts "no Arel::Visitors::SQLServer"

puts Gem.loaded_specs.map{|n,spec| spec }.sort{|x,y| -(x.dependencies.length <=> y.dependencies.length) }.inspect

begin 
# require('activerecord-sqlserver-adapter/arel/visitors/sqlserver')
puts "ActiveRecord::ConnectionAdapters::SQLServerAdapter loaded #{ActiveRecord::ConnectionAdapters::SQLServerAdapter}" rescue "no ActiveRecord::ConnectionAdapters::SQLServerAdapter"
puts("[SQL_SERVER_LOADING_DEBUG] Arel::Visitors::SQLServer constants: #{Arel::Visitors::SQLServer.inspect}") rescue puts "no Arel::Visitors::SQLServer"
rescue => e
 	"can't load activerecord-sqlserver-adapter/arel/visitors/sqlserver #{e.inspect}"
 end