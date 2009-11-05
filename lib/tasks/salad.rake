# 
# LICENSE
# 
# The MIT License
# 
# Copyright (c) 2009 Nederlandse Publieke Omroep
# Written by:
#   Bart Zonneveld (bart.zonneveld@omroep.nl)
#   Sjoerd Tieleman (sjoerd.tieleman@omroep.nl)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
# 

require 'cucumber/cli/main'

namespace :salad do
  desc "Run cucumber on multiple instances"
  task :features => :environment do
    def setup_database(conn, count)
      conn.merge! :database => "#{conn[:database]}_#{count}"
      connect_or_create_database(conn)
      Rake::Task["db:migrate"].invoke
    end
    
    # Copied from databases.rake
    def connect_or_create_database(conn)
      begin # Connect using the given connection
        ActiveRecord::Base.establish_connection(conn)
        ActiveRecord::Base.connection # This is needed to trigger an error if DB does not exist
      rescue # or create the database specified in the connection
        charset   = ENV['CHARSET']   || conn[:charset]   || 'utf8'
        collation = ENV['COLLATION'] || conn[:collation] || 'utf8_general_ci'

        ActiveRecord::Base.establish_connection(conn.merge(:database => nil))
        ActiveRecord::Base.connection.create_database(conn[:database], :charset => charset, :collation => collation)
        ActiveRecord::Base.establish_connection(conn)
      end
    end
    
    begin
      raise "RAILS_ENV is not set to test" unless Rails.env == 'test'
      features_dir = "features" # Set this to your features dir
      features = Dir[features_dir + '/**/*.feature'].sort_by { rand }
      feature_sets = []

      num_of_processes = ENV["SALAD_INSTANCES"] ? ENV["SALAD_INSTANCES"].to_i : 4
      num_of_processes.times { feature_sets << [] }

      features.each_with_index { |line, index| feature_sets[index % num_of_processes] << line }

      conn = ActiveRecord::Base.remove_connection
      
      pids = []
      
      num_of_processes.times do |count|
        pids << Process.fork do
          setup_database(conn, count)
          Cucumber::Cli::Main.execute(["-f", "progress", "-r", features_dir] + feature_sets[count])
        end
      end

      # Handle interrupt by user
      Signal.trap 'INT' do
        STDERR.puts("User interrupted, exiting...")
        pids.each { |pid| Process.kill "KILL", pid }
        exit 1
      end
      
      pids.each { Process.wait }

    rescue Exception => e
      STDERR.puts("#{e.message} (#{e.class})")
      STDERR.puts(e.backtrace.join("\n"))
      Kernel.exit 1
    end
  end
end