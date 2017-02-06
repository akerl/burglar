require 'csv'
require 'date'

module LogCabin
  module Modules
    ##
    # American Express
    module AmericanExpress
      include Burglar.helpers.find(:creds)
      include Burglar.helpers.find(:ledger)
      include Burglar.helpers.find(:mechanize)

      # rubocop:disable Metrics/LineLength
      AMEX_DOMAIN = 'https://online.americanexpress.com'.freeze
      AMEX_LOGIN_PATH = '/myca/logon/us/action/LogonHandler?request_type=LogonHandler&Face=en_US'.freeze
      AMEX_LOGIN_FORM = 'lilo_formLogon'.freeze
      AMEX_CSV_PATH = '/myca/estmt/us/downloadTxn.do'.freeze
      # rubocop:enable Metrics/LineLength

      def raw_transactions
        @raw_transactions ||= csv.map do |row|
          raw_date, raw_amount, raw_name = row.values_at(0, 7, 11)
          date = Date.strptime(raw_date, '%m/%d/%Y %a')
          amount = format('$%.2f', raw_amount)
          name = raw_name.empty? ? 'Amex Payment' : raw_name.downcase
          simple_ledger(date, name, amount)
        end
      end

      private

      def default_account_name
        'Liabilities:Credit:american_express'.freeze
      end

      def user
        @user ||= @options[:user]
      end

      def password
        @password ||= creds(AMEX_DOMAIN, user)
      end

      def setup_mech
        page = mech.get(AMEX_DOMAIN + AMEX_LOGIN_PATH)
        form = page.form_with(id: AMEX_LOGIN_FORM) do |f|
          f.UserID = user
          f.Password = password
        end
        form.submit
      end

      def csv
        CSV.parse(csv_page.body)
      end

      def csv_page
        params = static_fields.merge(
          'startDate' => begin_date.strftime('%m%d%Y'),
          'endDate' => end_date.strftime('%m%d%Y')
        )
        mech.post(AMEX_DOMAIN + AMEX_CSV_PATH, params)
      end

      def static_fields
        @static_fields ||= {
          'request_type' => 'authreg_Statement',
          'downloadType' => 'C',
          'downloadView' => 'C',
          'downloadWithETDTool' => 'true',
          'viewType' => 'L',
          'reportType' => '1',
          'BPIndex' => '-99'
        }.freeze
      end
    end
  end
end
