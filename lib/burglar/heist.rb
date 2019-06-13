require 'cymbal'
require 'yaml'

module Burglar
  # Default config file
  DEFAULT_CONFIG_FILE = '~/.burglar.yml'.freeze

  ##
  # Collection of banks
  class Heist
    def initialize(params = {})
      @options = load_options(params)
    end

    def banks
      @banks ||= @options[:banks].map do |k, v|
        [k, Burglar::Bank.new(@options.merge(v))]
      end.to_h
    end

    def transactions
      @transactions ||= Ledger.new(
        entries: banks.map { |_, v| v.transactions.entries }.flatten.sort
      )
    end

    private

    def load_config(file)
      file ||= DEFAULT_CONFIG_FILE
      file = File.expand_path file
      Cymbal.symbolize YAML.safe_load(File.read(file))
    end

    def load_options(params)
      load_config(params[:config]).merge(params)
    end
  end
end
