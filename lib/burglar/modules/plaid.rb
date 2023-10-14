Burglar.extra_dep('plaid', 'plaid')

module LogCabin
  module Modules
    ##
    # Plaid
    module Plaid # rubocop:disable Metrics/ModuleLength
      include Burglar.helpers.find(:creds)
      include Burglar.helpers.find(:ledger)

      PLAID_DOMAIN = 'https://plaid.com'.freeze

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

      def balance
        @balance ||= load_balance
      end

      private

      def api_configuration
        @api_configuration ||= ::Plaid::Configuration.new do |c|
          c.server_index = ::Plaid::Configuration::Environment['development']
          c.api_key['PLAID-CLIENT-ID'] = client_id
          c.api_key['PLAID-SECRET'] = secret_key
          c.api_key['Plaid-Version'] = '2020-09-14'
        end
      end

      def api_client
        @api_client ||= ::Plaid::ApiClient.new api_configuration
      end

      def client
        @client ||= ::Plaid::PlaidApi.new(api_client)
      end

      def load_balance
        resp = client.accounts_balance_get(::Plaid::AccountsBalanceGetRequest.new(
                                             access_token: access_token,
                                             options: ::Plaid::AccountsBalanceGetRequestOptions.new(
                                               account_ids: [account_id]
                                             )
                                           ))
        resp.accounts.first.balances.current
      end

      def get_transactions_page(offset)
        resp = client.transactions_get(::Plaid::TransactionsGetRequest.new(
                                         access_token: access_token,
                                         start_date: begin_date_str,
                                         end_date: end_date_str,
                                         options: ::Plaid::TransactionsGetRequestOptions.new(
                                           account_ids: [account_id],
                                           offset: offset
                                         )
                                       ))
        [resp.transactions, resp.total_transactions]
      end

      def all_transactions
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

      def accounts
        @accounts || client.accounts_get(::Plaid::AccountsGetRequest.new(access_token: access_token)).accounts
      end

      def account
        @account ||= accounts.first if accounts.size == 1
        @account ||= accounts.find { |x| x.name == account_clean_name }
      end

      def account_id
        @account_id ||= account.account_id
      end

      def account_clean_name
        @account_clean_name ||= @options[:name] || raise(
          'Account name needed (more than one option) but not provided'
        )
      end

      def client_id
        @client_id ||= creds(PLAID_DOMAIN, 'client_id')
      end

      def secret_key
        @secret_key ||= creds(PLAID_DOMAIN, 'secret_key')
      end

      def access_token
        @access_token ||= creds(PLAID_DOMAIN, account_name)
      end
    end
  end
end
