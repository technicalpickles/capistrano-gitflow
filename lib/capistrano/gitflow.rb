# require 'capistrano'
require File.join(File.dirname(__FILE__), 'gitflow', 'natcmp')
require 'stringex'

require 'capistrano/version'

if defined?(Capistrano::VERSION) && Capistrano::VERSION.to_s.split('.').first.to_i >= 3
  require  File.join(File.dirname(__FILE__), 'tasks', 'gitflow')
else
   require File.join(File.dirname(__FILE__), 'gitflow','recipes', 'gitflow')
end
