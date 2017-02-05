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
      @transactions ||= banks.map { |_, v| v.transactions }.flatten
    end
  end
end
