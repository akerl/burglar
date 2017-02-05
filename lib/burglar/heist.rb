module Burglar
  ##
  # Collection of banks
  class Heist
    def initialize(params = {})
      @options = params
    end

    def banks
      @banks ||= @options[:banks].map { |k, v| [k, Burglar::Bank.new(v)] }.to_h
    end

    def transactions
      @transactions ||= Ledger.new(
        entries: banks.map { |_, v| v.transactions.entries }.flatten
      )
    end
  end
end
