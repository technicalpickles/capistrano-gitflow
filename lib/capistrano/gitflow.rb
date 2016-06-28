# require 'capistrano'
require 'stringex'
Gem.find_files('capistrano/gitflow/helpers/**/*.rb').each { |path| require path }
require 'capistrano/version'


module CapistranoGitFlow
  class << self
    def cap_major_version
      defined?(Capistrano::VERSION) ? Capistrano::VERSION.to_s.split('.').first.to_i : nil
    end

    def is_using_cap3?
      cap_major_version.to_i > 0 && cap_major_version >= 3
    end
  end
end

unless defined?(Sinatra)
  if CapistranoGitFlow.is_using_cap3?
    require 'capistrano/all'
    require  File.join(File.dirname(__FILE__), 'tasks', 'gitflow')
  else
    require 'capistrano'
    require File.join(File.dirname(__FILE__), 'gitflow','legacy', 'gitflow')
  end
end
