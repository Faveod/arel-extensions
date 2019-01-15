module ArelExtensions
  class CommonSqlFunctions

    def initialize(cnx)
      @cnx = cnx
      if cnx && cnx.adapter_name =~ /sqlite/i && !$load_extension_disabled
        begin
          db = cnx.raw_connection
          db.enable_load_extension(1)
          db.load_extension("/usr/lib/sqlite3/pcre.so")
          db.load_extension("/usr/lib/sqlite3/extension-functions.so")
          db.enable_load_extension(0)
        rescue => e
          $load_extension_disabled = true
          puts "can not load extensions #{e.inspect}"
        end
      end
    end

    def add_sqlite_functions
      db = @cnx.raw_connection
      db.create_function("find_in_set", 1) do |func, val, list|
        case list
        when String
          i = list.split(',').index(val.to_s)
          func.result = i ? (i+1) : 0
        when NilClass
          func.result = nil
        else
          i = list.to_s.split(',').index(val.to_s)
          func.result = i ? (i+1) : 0
        end
      end
      db.create_function("instr", 1) do |func, value1, value2|
        i = value1.to_s.index(value2.to_s)
        func.result = i ? (i+1) : 0
      end rescue "function instr already here (>= 3.8.5)"
    end

    def add_sql_functions(env_db = nil)
      env_db ||= @cnx.adapter_name
      if env_db =~ /sqlite/i
        begin
          add_sqlite_functions
        rescue => e
          puts "can not add sqlite functions #{e.inspect}"
        end
      end
      if File.exist?("init/#{env_db}.sql")
        sql = File.read("init/#{env_db}.sql")
        if env_db == 'mssql'
          sql.split(/^GO\s*$/).each {|str|
            @cnx.execute(str.strip) unless str.blank?
          }
        elsif env_db == 'mysql' 
			sql.split("$$")[1..-2].each { |str|
				@cnx.execute(str.strip) unless str.strip.blank?
			}
        else
          @cnx.execute(sql) unless sql.blank?
        end
      end
    end

  end
end
