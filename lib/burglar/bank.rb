module Burglar
  ##
  # Single bank's information
  class Bank
    def initialize(params = {})
      @options = params
      extend module_obj
    end

    private

    def type
      @type ||= @options[:type] || raise('Must supply an account type')
    end

    def module_obj
      @module_obj ||= Burglar.modules.find(type) || raise("No module: #{type}")
    end
  end
end
