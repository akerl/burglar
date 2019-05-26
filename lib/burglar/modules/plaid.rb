require 'plaid'

module LogCabin
  module Modules
    ##
    # Plaid
    module Plaid
      include Burglar.helpers.find(:creds)
      include Burglar.helpers.find(:ledger)

      PLAID_DOMAIN = 'https://plaid.com'.freeze

      def raw_transactions # rubocop:disable Metrics/MethodLength
        @raw_transactions ||= all_transactions.map do |row|
          ::Ledger::Entry.new(
            name: row.name.downcase,
            state: row.pending ? :pending : :cleared,
            date: row.date,
            actions: [
              { name: guess_action(row.name.downcase), amount: row.amount },
              { name: account_name }
            ]
          )
        end
      end

      private

      def api_client
        @api_client ||= ::Plaid::Client.new(
          env: 'development',
          client_id: client_id,
          secret: secret_key,
          public_key: public_key
        )
      end

      def get_transactions_page(offset)
        resp = api_client.transactions.get(
          access_token,
          begin_date_str,
          end_date_str,
          account_ids: [account_id],
          offset: offset
        )
        [resp.transactions, resp.total_transactions]
      end

      def all_transactions
        return @all_transactions if @all_transactions
        list, total = get_transactions_page(0)
        while list.length < total
          new, total = get_transactions_page(list.length)
          list += new
        end
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

      def accounts
        @accounts ||= api_client.accounts.get(access_token)['accounts']
      end

      def account_id
        @account_id ||= accounts.find do |x|
          x['name'] == account_name
        end['account_id']
      end

      def account_name
        @account_name ||= @options[:name] || raise('No account name provided')
      end

      def client_id
        @client_id ||= creds(PLAID_DOMAIN, 'client_id')
      end

      def secret_key
        @secret_key ||= creds(PLAID_DOMAIN, 'secret_key')
      end

      def public_key
        @public_key ||= creds(PLAID_DOMAIN, 'public_key')
      end

      def access_token
        @access_token ||= creds(PLAID_DOMAIN, account)
      end
    end
  end
end
