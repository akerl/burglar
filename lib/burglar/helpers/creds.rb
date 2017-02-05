Prospectus.extra_dep('creds', 'keylime')

module LogCabin
  module Modules
    ##
    # Provide a helper to access OSX keychain credentials
    module Creds
      def creds(server, account)
        credential = Keylime.new(server: server, account: account)
        credential.get!("Enter password for #{server} (#{account})").password
      end
    end
  end
end
