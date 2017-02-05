module LogCabin
  module Modules
    ##
    # American Express
    module AmericanExpress
      include Prospectus.helpers.find(:creds)

      def transactions
        require 'pry'
        binding.pry # rubocop:disable Lint/Debugger
      end
    end
  end
end
