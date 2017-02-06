Burglar.extra_dep('mechanize', 'mechanize')

module LogCabin
  module Modules
    ##
    # Provide a helper to scrape websites
    module Mechanize
      def mech
        return @mech if @mech
        @mech = ::Mechanize.new
        setup_mech if respond_to? :setup_mech, true
        @mech
      end
    end
  end
end
