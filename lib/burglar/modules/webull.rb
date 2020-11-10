Burglar.extra_dep('webull', 'webull')

module LogCabin
  module Modules
    ##
    # Webull
    module Webull
      include Burglar.helpers.find(:creds)
      include Burglar.helpers.find(:ledger)

      WEBULL_DOMAIN = 'https://webull.com'

      def raw_transactions # rubocop:disable Metrics/MethodLength
        @raw_transactions ||= all_transactions.map do |row|
          amount = format('$%.2f', row.amount)
          name = row.name.downcase
          action = guess_action(name)
          state = row.pending ? :pending : :cleared

          ::Ledger::Entry.new(
            name: name,
            state: state,
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
        @all_transactions = api_client.transactions.select {

        return @all_transactions if @all_transactions
        list, total = get_transactions_page(0)
        while list.length < total
          new, total = get_transactions_page(list.length)
          list += new
        end
        list.reject!(&:pending) unless @options[:pending]
        @all_transactions = list
      end

      def begin_date_str
        @begin_date_str ||= date_str(begin_date)
      end

      def end_date_str
        @end_date_str ||= date_str(end_date)
      end

      def date_str(date)
        date.strftime('%Y-%m-%d')
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
