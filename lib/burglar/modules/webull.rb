Burglar.extra_dep('webull', 'webull')

module LogCabin
  module Modules
    ##
    # Webull
    module Webull
      include Burglar.helpers.find(:creds)
      include Burglar.helpers.find(:ledger)

      WEBULL_DOMAIN = 'https://webull.com'

      def raw_transactions
        @raw_transactions ||= filtered_orders.map do |row|
          ::Ledger::Entry.new(
            name: "#{row[:action]} #{,
            state: :cleared,
            date: row[:date],
            actions: [
              { name: action, amount: amount },
              { name: account_name }
            ],
            tags: { 'transaction_id' => row[:id] }
          )
        end
      end

      private

      def all_events
        @all_events ||= api_client.orders(status: 'Filled', pageSize: 999)
      end

      def all_orders
        @all_orders ||= all_events.map { |x| x.orders }.flatten
      end

      def parsed_orders
        @parsed_orders ||= all_orders.map do |x|
          {
            id: x['orderId']
            symbol: x['symbol'],
            action: x['action'],
            quantity: x['filledQuantity'],
            date: Time.at(x['filledTime0'] / 1000).to_date,
            total: x['filledValue'],
            price: x['avgFilledPrice']
          }
        end
      end

      def filtered_orders
        @filtered_orders ||= parsed_orders.select do |x|
          x['date'] >= begin_date && x['date'] <= end_date
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
