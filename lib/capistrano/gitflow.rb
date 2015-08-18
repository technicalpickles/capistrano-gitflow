# require 'capistrano'
require 'stringex'
Gem.find_files('capistrano/gitflow/helpers/**/*.rb').each { |path| require path }
require 'capistrano/version'

self.extend CapistranoGitFlow::Helper
include CapistranoGitFlow::Helper

unless defined?(Sinatra)
  if gitflow_using_cap3?
    require 'capistrano/all'
    require  File.join(File.dirname(__FILE__), 'tasks', 'gitflow')
  else
    require 'capistrano'
    require File.join(File.dirname(__FILE__), 'gitflow','legacy', 'gitflow')
  end
end
