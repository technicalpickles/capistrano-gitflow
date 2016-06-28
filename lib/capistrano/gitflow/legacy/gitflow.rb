require 'capistrano'

module Capistrano
  class Gitflow
    def self.load_into(capistrano_configuration)
      capistrano_configuration.class.class_eval do
        include CapistranoGitFlow::BaseHelper
      end
      capistrano_configuration.load  File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'tasks', 'gitflow.rb')
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Gitflow.load_into(Capistrano::Configuration.instance)
end
