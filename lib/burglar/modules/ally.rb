require 'json'
require 'csv'
require 'date'

module LogCabin
  module Modules
    ##
    # Ally
    module Ally
      include Burglar.helpers.find(:creds)
      include Burglar.helpers.find(:mechanize)
      include Burglar.helpers.find(:ledger)

      ALLY_DOMAIN = 'https://secure.ally.com'.freeze
      ALLY_CSRF_URL = ALLY_DOMAIN + '/capi-gw/session/status/olbWeb'
      ALLY_AUTH_URL = ALLY_DOMAIN + '/capi-gw/customer/authentication'
      ALLY_MFA_URL = ALLY_DOMAIN + '/capi-gw/notification'
      ALLY_DEVICE_URL = ALLY_DOMAIN + '/capi-gw/customer/device'
      ALLY_ACCOUNT_URL = ALLY_DOMAIN + '/capi-gw/accounts'

      def raw_transactions
        csv.map do |x|
          amount = format('$%.2f', x[:amount] * -1)
          simple_ledger(x[:date], x[:description], amount)
        end
      end

      private

      def default_account_name
        'Assets:' + @options[:name].gsub(/\s/, '')
      end

      def raw_csv_url
        ALLY_DOMAIN + "/capi-gw/accounts/#{account_id}/transactions.csv"
      end

      def raw_csv
        @raw_csv ||= mech.get(raw_csv_url, csv_data, referrer, csv_headers)
      end

      def csv
        @csv ||= CSV.new(
          raw_csv.body,
          headers: true,
          header_converters: :symbol,
          converters: [:date, :float]
        ).map(&:to_h)
      end

      def csv_data
        @csv_data ||= {
          'patron-id' => 'olbWeb',
          'fromDate' => begin_date.strftime('%Y-%m-%d'),
          'toDate' => end_date.strftime('%Y-%m-%d'),
          'status' => 'Posted'
        }
      end

      def user
        @user ||= @options[:user]
      end

      def password
        @password ||= creds(ALLY_DOMAIN, user)
      end

      def csrf_token
        @csrf_token ||= mech.get(ALLY_CSRF_URL).response['csrfchallengetoken']
      end

      def device_token
        return @device_token if @device_token
        res = `system_profiler SPHardwareDataType`
        @device_token = res.lines.grep(/Serial Number/).first.split.last
      end

      def auth_headers
        @auth_headers = {
          'CSRFChallengeToken' => csrf_token,
          'ApplicationName' => 'AOB',
          'ApplicationId' => 'ALLYUSBOLB',
          'spname' => 'auth',
          'Accept' => 'application/v1+json',
          'ApplicationVersion' => '1.0'
        }
      end

      def account_headers
        @accounts_headers = {
          'spname' => 'common-api',
          'BankAPIVersion' => '2.9',
          'CSRFChallengeToken' => csrf_token,
          'Accept' => 'application/vnd.api+json',
          'patron-id' => 'olbWeb',
          'Accept-Encoding' => 'gzip, deflate, sdch, br',
          'Accept-Language' => 'en-US,en;q=0.8'
        }
      end

      def csv_headers
        @csv_headers = {
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8', # rubocop:disable Metrics/LineLength
          'Accept-Encoding' => 'gzip, deflate, sdch, br',
          'Accept-Language' => 'en-US,en;q=0.8'
        }
      end

      def referrer
        'https://secure.ally.com/'
      end

      def auth_data
        @auth_data = {
          'userNamePvtEncrypt' => user,
          'passwordPvtBlock' => password,
          'rememberMeFlag' => 'false',
          'channelType' => 'OLB',
          'devicePrintRSA' => device_token
        }
      end

      def setup_mech
        auth = mech.post(ALLY_AUTH_URL, auth_data, auth_headers)
        auth_res = JSON.parse(auth.body)
        mfa(auth_res) if auth_res['authentication']['mfa']
      end

      def mfa_data(payload)
        mfa_methods = payload['authentication']['mfa']['mfaDeliveryMethods']
        mfa_id = mfa_methods.first['deliveryMethodId']
        {
          'deliveryMethodId' => mfa_id,
          'devicePrintRSA' => device_token,
          'channelType' => 'OLB'
        }
      end

      def mfa(payload)
        mech.post(ALLY_MFA_URL, mfa_data(payload), auth_headers)
        token = UserInput.new(message: 'MFA token', validation: /^\d+$/).ask
        mech.post(ALLY_AUTH_URL + '?_method=PATCH', { 'otpCodePvtBlock' => token, 'devicePrintRSA' => device_token }, auth_headers)
        mech.post(ALLY_DEVICE_URL + '?_method=PATCH', { 'devicePrintRSA' => device_token }, auth_headers)
      end

      def accounts
        @accounts ||= JSON.parse(
          mech.get(ALLY_ACCOUNT_URL, [], referrer, account_headers).body
        )
      end

      def account
        return @account if @account
        list = accounts['accounts']['deposit']['accountSummary']
        match = list.find { |x| x['accountNickname'].match @options[:name] }
        raise('No matching account found') unless match
        @account = match
      end

      def account_id
        @account_id ||= account['accountId']
      end
    end
  end
end
