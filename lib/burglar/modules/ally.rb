require 'json'
require 'csv'
require 'date'
require 'digest/sha1'

module LogCabin
  module Modules
    ##
    # Ally
    module Ally # rubocop:disable Metrics/ModuleLength
      include Burglar.helpers.find(:creds)
      include Burglar.helpers.find(:mechanize)
      include Burglar.helpers.find(:ledger)

      ALLY_DOMAIN = 'https://secure.ally.com'.freeze
      ALLY_CSRF_URL = ALLY_DOMAIN + '/capi-gw/session/status/olbWeb'
      ALLY_AUTH_URL = ALLY_DOMAIN + '/capi-gw/customer/authentication'
      ALLY_AUTH_PATCH_URL = ALLY_AUTH_URL + '?_method=PATCH'
      ALLY_MFA_URL = ALLY_DOMAIN + '/capi-gw/notification'
      ALLY_DEVICE_URL = ALLY_DOMAIN + '/capi-gw/customer/device'
      ALLY_DEVICE_PATCH_URL = ALLY_DEVICE_URL + '?_method=PATCH'
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
        csv_headers = headers('text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8') # rubocop:disable Metrics/LineLength
        @raw_csv ||= mech.get(raw_csv_url, csv_data, nil, csv_headers)
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
        mech
        @csrf_token ||= mech.get(ALLY_CSRF_URL).response['csrfchallengetoken']
      end

      def device_token
        return @device_token if @device_token
        res = `system_profiler SPHardwareDataType`
        raw_token = res.lines.grep(/Serial Number/).first.split.last
        @device_token = Digest::SHA1.hexdigest raw_token
      end

      def headers(accept, spname = nil)
        {
          'CSRFChallengeToken' => csrf_token,
          'ApplicationName' => 'AOB',
          'ApplicationId' => 'ALLYUSBOLB',
          'ApplicationVersion' => '1.0',
          'Accept' => accept,
          'spname' => spname
        }.reject { |_, v| v.nil? }
      end

      def auth_headers
        @auth_headers ||= headers('application/v1+json', 'auth')
      end

      def common_data
        @common_data = {
          'channelType' => 'OLB',
          'devicePrintRSA' => device_token
        }
      end

      def auth_data
        @auth_data = common_data.merge(
          'userNamePvtEncrypt' => user,
          'passwordPvtBlock' => password,
          'rememberMeFlag' => 'false'
        )
      end

      def setup_mech
        auth = mech.post(ALLY_AUTH_URL, auth_data, auth_headers)
        auth_res = JSON.parse(auth.body)
        mfa(auth_res) if auth_res['authentication']['mfa']
      end

      def mfa_data(payload)
        mfa_methods = payload['authentication']['mfa']['mfaDeliveryMethods']
        mfa_id = mfa_methods.first['deliveryMethodId']
        common_data.merge('deliveryMethodId' => mfa_id)
      end

      def mfa_token
        UserInput.new(message: 'MFA token', validation: /^\d+$/).ask
      end

      def mfa(payload)
        mech.post(ALLY_MFA_URL, mfa_data(payload), auth_headers)
        data = common_data.merge('otpCodePvtBlock' => mfa_token)
        mech.post(ALLY_AUTH_PATCH_URL, data, auth_headers)
        mech.post(ALLY_DEVICE_PATCH_URL, common_data, auth_headers)
      end

      def accounts
        account_headers = headers('application/vnd.api+json', 'common-api')
        @accounts ||= JSON.parse(
          mech.get(ALLY_ACCOUNT_URL, [], nil, account_headers).body
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
