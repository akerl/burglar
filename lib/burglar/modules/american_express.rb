require 'csv'
require 'date'

Burglar.extra_dep('american_express', 'mechanize')

module LogCabin
  module Modules
    ##
    # American Express
    module AmericanExpress
      include Burglar.helpers.find(:creds)

      # rubocop:disable Metrics/LineLength
      AMEX_DOMAIN = 'https://online.americanexpress.com'.freeze
      AMEX_LOGIN_PATH = '/myca/logon/us/action/LogonHandler?request_type=LogonHandler&Face=en_US'.freeze
      AMEX_LOGIN_FORM = 'lilo_formLogon'.freeze
      AMEX_CSV_PATH = '/myca/estmt/us/downloadTxn.do'.freeze
      # rubocop:enable Metrics/LineLength

      def transactions
        rows = csv.map { |x| x.values_at(0, 7, 11) }
        require 'pry'
        binding.pry # rubocop:disable Lint/Debugger
        rows.map do |raw_date, raw_amount, raw_name|
          date = Date.strptime(raw_date, '%m/%d/%Y %a')
          amount = format('%.2f', raw_amount)
          name = raw_name.empty? ? 'Amex Payment' : raw_name.downcase
          [date, amount, name]
        end
      end

      private

      def start_date
        Date.today
      end

      def end_date
        start_date - 35
      end

      def user
        @user ||= @options[:user]
      end

      def password
        @password ||= creds(AMEX_DOMAIN, user)
      end

      def mech
        @mech ||= Mechanize.new
      end

      def login!
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
        login!
        params = static_fields.merge(
          'startDate' => start_date.strftime('%m%d%Y'),
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
