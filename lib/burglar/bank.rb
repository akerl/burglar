module Burglar
  ##
  # Single bank's information
  class Bank
    def initialize(params = {})
      @options = params
      extend module_obj
    end

    def transactions
      Ledger.new(entries: raw_transactions)
    end

    def begin_date
      @begin_date ||= @options[:begin]
    end

    def end_date
      @end_date ||= @options[:end]
    end

    def account_name
      @account_name ||= @options[:account] || default_account_name
    end

    private

    def default_account_name
      raise('Module failed to override default_account_name')
    end

    def type
      @type ||= @options[:type] || raise('Must supply an account type')
    end

    def module_obj
      @module_obj ||= Burglar.modules.find(type) || raise("No module: #{type}")
    end
  end
end
