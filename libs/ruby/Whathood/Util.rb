module Whathood

    class Util

        def self.exec_sql_stmt(sql_stmt,db_name)
            puts "executing #{sql_stmt}"
            puts `sudo -u postgres psql --tuples-only -c "#{sql_stmt}" #{db_name}`
        end

		def self.check_for_root_user()
			username = ENV['USER']

			if username != 'root' and username != 'vagrant'
				abort 'must run script as root'
			end
		end

		def self.prompt_user(str)
			print str
			option = gets
		end
    end
end
