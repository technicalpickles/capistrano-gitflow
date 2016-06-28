module CapistranoGitFlow
  module Base
    class << self
      def cap_major_version
        defined?(Capistrano::VERSION) ? Capistrano::VERSION.to_s.split('.').first.to_i : nil
      end

      # Description of method
      #
      # @return [Type] description of returned object
      def is_using_cap3?
        cap_major_version.to_i > 0 && cap_major_version >= 3
      end
    end
  end
end
