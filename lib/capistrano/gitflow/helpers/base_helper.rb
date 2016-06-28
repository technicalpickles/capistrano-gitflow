require_relative '../base'
require_relative './shared_helper'
require_relative './modern_helper'
require_relative './legacy_helper'
module CapistranoGitFlow
  module BaseHelper

    def self.included(base)
      base.send(:include, CapistranoGitFlow::SharedHelper)
      if CapistranoGitFlow::Base.is_using_cap3?
        base.send(:include, CapistranoGitFlow::ModernHelper)
      else
        base.send(:include, CapistranoGitFlow::LegacyHelper)
      end
    end

  end
end
