# require 'capistrano'
require 'stringex'
Gem.find_files('capistrano/gitflow/helpers/**/*.rb').each { |path| require path }
require 'capistrano/version'

unless defined?(Sinatra)
  if CapistranoGitFlow::Base.is_using_cap3?
    require 'capistrano/all'
    require  File.join(File.dirname(__FILE__), 'tasks', 'gitflow')
  else
    require 'capistrano'
    require File.join(File.dirname(__FILE__), 'gitflow','legacy', 'gitflow')
  end
end
