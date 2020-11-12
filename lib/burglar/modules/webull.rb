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
        @raw_transactions ||= all_transactions.map do |row|
          ::Ledger::Entry.new(
            name: name,
            state: :cleared,
            date: row.date,
            actions: [
              { name: action, amount: amount },
              { name: account_name }
            ],
            tags: { 'transaction_id' => row.transaction_id }
          )
        end
      end

      private


      def all_transactions
        @all_transactions = api_client.transactions(
          after: begin_date,
          before: end_date,
          type: 'filled'
        )
      end

      def api_client
        return @api_client if @api_client
        generate_tokens unless refresh_token && access_token
        @api_client = ::Webull.new(refresh_token, access_token)
        store_tokens @api_client.refresh_token
        @api_client
      end

      def generate_tokens
        store_tokens Webull.generate_tokens
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
    end
  end
end
