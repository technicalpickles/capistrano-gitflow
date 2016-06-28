require_relative './shared_helper'
module CapistranoGitFlow
  module LegacyHelper
    include CapistranoGitFlow::SharedHelper

    def gitflow_callbacks
      before "deploy:update_code", "gitflow:verify_up_to_date"
      super
    end

    def gitflow_find_task(name)
      exists(name)
    rescue
      nil
    end

    def gitflow_execute_task(name)
      find_and_execute_task(name)
    end

    def gitflow_capistrano_tag
      capistrano_configuration[:tag]
    end

    def gitflow_ask_confirm(message)
      Capistrano::CLI.ui.ask("#{message}")
    end

  end
end
