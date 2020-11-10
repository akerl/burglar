Burglar.extra_dep('creds', 'keylime')

module LogCabin
  module Modules
    ##
    # Provide a helper to access OSX keychain credentials
    module Creds
      def creds(server, account)
        credential = Keylime.new(server: server, account: account)
        credential.get!("Enter password for #{server} (#{account})").password
      end

      def stored_creds(server, account)
        item = keylime.new(server: server, account: account).get
        item ? item.password : nil
      end

      def store_cred(server, account, secret)
        keylime.new(server: server, account: account).set(secret)
      end
    end
  end
end
