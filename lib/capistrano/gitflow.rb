# require 'capistrano'
require 'stringex'
Gem.find_files('capistrano/gitflow/helpers/**/*.rb').each { |path| require path }
require 'capistrano/version'

self.extend CapistranoGitFlow::Helper
include CapistranoGitFlow::Helper


if CapistranoGitFlow::Helper.using_cap3?
  require  File.join(File.dirname(__FILE__), 'tasks', 'gitflow')
else
  require File.join(File.dirname(__FILE__), 'gitflow','legacy', 'gitflow')
end
