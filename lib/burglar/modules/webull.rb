Burglar.extra_dep('webull', 'webull')

module LogCabin
  module Modules
    ##
    # Webull
    module Webull
      include Burglar.helpers.find(:creds)
      include Burglar.helpers.find(:ledger)

      WEBULL_DOMAIN = 'https://webull.com'.freeze

      def raw_transactions # rubocop:disable Metrics/MethodLength
        @raw_transactions ||= filtered_orders.map do |row|
          actions = parse_actions(row)
          ::Ledger::Entry.new(
            name: "#{row[:action]} #{row[:quantity]} #{row[:symbol]} at #{row[:price]}", # rubocop:disable Metrics/LineLength
            state: :cleared,
            date: row[:date],
            actions: actions,
            tags: { 'transaction_id' => row[:id] }
          )
        end
      end

      private

      def parse_actions(x)
        [
          { name: account_name, amount: "#{'-' if x[:action] == 'SELL'}#{x[:quantity]} #{x[:symbol]} @ $#{x[:price] / 100.0}" },
          { name: account_name, amount: "#{'-' if x[:action] == 'BUY'}$#{x[:total] / 100.0}" }
        ]
      end

      def all_events
        @all_events ||= api_client.orders(status: 'Filled', pageSize: 999)
      end

      def all_orders
        @all_orders ||= all_events.map { |x| x['orders'] }.flatten
      end

      def parsed_orders # rubocop:disable Metrics/MethodLength
        @parsed_orders ||= all_orders.map do |x|
          {
            id: x['orderId'],
            symbol: x['symbol'],
            action: x['action'],
            quantity: x['filledQuantity'].to_i,
            date: Time.at(x['filledTime0'] / 1000).to_datetime,
            total: (x['filledValue'].to_f * 100).to_i,
            price: (x['avgFilledPrice'].to_f * 100).to_i
          }
        end
      end

      def matched_orders
        @matched_orders ||= WebullBasisResolver.new(parsed_orders).orders
      end

      def filtered_orders
        @filtered_orders ||= matched_orders.select do |x|
          x[:date] >= begin_date && x[:date] <= end_date
        end
      end

      def api_client
        return @api_client if @api_client
        @api_client = ::Webull.new(tokens: tokens, udid: udid)
        store_tokens @api_client.refresh
        @api_client
      end

      def tokens
        @tokens ||= if access_token && refresh_token
                      ::Webull::Tokens.new(
                        access: access_token,
                        refresh: refresh_token
                      )
                    else
                      ::Webull.generate_tokens(udid)
                    end
      end

      def store_tokens(tokens)
        store_cred(WEBULL_DOMAIN, 'refresh_token', tokens.refresh)
        store_cred(WEBULL_DOMAIN, 'access_token', tokens.access)
      end

      def refresh_token
        @refresh_token ||= stored_creds(WEBULL_DOMAIN, 'refresh_token')
      end

      def access_token
        @access_token ||= stored_creds(WEBULL_DOMAIN, 'access_token')
      end

      def udid
        @udid ||= @options[:device_name] || raise('Must supply a device_name')
      end
    end
  end
end

class WebullBasisResolver
  attr_reader :raw_orders

  def initialize(raw_orders)
    @raw_orders = raw_orders.sort_by { |x| x[:date] }.reverse
  end

  def orders
    return @orders if @orders
    buy_stack = order_timeline.dup
    @orders = raw_orders.each_with_object([]) do |item, acc|
      item = item.dup
      if item[:action] == 'SELL'
        item[:cost_basis] = []
        buy_stack.delete_if do |x|
          next false if item[:cost_basis].size == item[:quantity]
          next false if x[:symbol] != item[:symbol]
          item[:cost_basis] << x[:price]
        end
      end
      acc << item
    end
  end

  def buy_orders
    @buy_orders ||= raw_orders.select { |x| x[:action] == 'BUY' }
  end

  def order_timeline
    @order_timeline ||= buy_orders.flat_map do |x|
      1.upto(x[:quantity].to_i).map do
        {
          symbol: x[:symbol],
          action: x[:action],
          date: x[:date],
          price: x[:price]
        }
      end
    end
  end
end
