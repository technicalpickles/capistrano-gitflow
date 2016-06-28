require_relative './shared_helper'
module CapistranoGitFlow
  module ModernHelper
    include CapistranoGitFlow::SharedHelper

    def gitflow_callbacks
      before "deploy", "gitflow:verify_up_to_date"
      super
    end

    def gitflow_find_task(name)
      ::Rake::Task[name]
    rescue
      nil
    end


    def gitflow_execute_task(name)
      gitflow_find_task(name).invoke
    end

    def gitflow_capistrano_tag
      ENV['TAG']
    end

    def gitflow_ask_confirm(message)
      $stdout.print "#{message}"
      $stdin.gets.to_s.chomp
    end

  end
end
