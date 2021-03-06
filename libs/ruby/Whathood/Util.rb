module Whathood

    class Util

        def self.run_cmd(cmd)
    	    puts cmd
            unless system cmd
                abort "could not run command: '#{cmd}'"
            end
        end

        def self.exec_sql_stmt(sql_stmt,db_name)
            puts "executing #{sql_stmt}"
            puts `sudo -u postgres psql --tuples-only -c "#{sql_stmt}" #{db_name}`
        end

        # just check for root and not vagrant
		def self.check_for_just_root_user()
			username = ENV['USER']

			if username != 'root'
				abort 'must run script as root'
			end
		end

		def self.check_for_root_user()
			username = ENV['USER']

			if username != 'root' and username != 'vagrant'
				abort 'must run script as root or vagrant'
			end
		end

		def self.prompt_user(str)
			print "#{str} Enter to continue; [CTRL-C] to abort"
			option = gets
		end
    end
end
