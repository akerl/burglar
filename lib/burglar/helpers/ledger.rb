module LogCabin
  module Modules
    ##
    # Provide a helper to create simple Ledger objects
    module Ledger
      def simple_ledger(date, name, amount)
        ::Ledger::Entry.new(
          name: name,
          state: date > Date.today ? :pending : :cleared,
          date: date.strftime('%Y/%m/%d'),
          actions: [
            { name: guess_action(name), amount: amount },
            { name: account_name }
          ]
        )
      end

      def guess_action(name)
        guess = `ledger xact '#{name.delete("'")}' 2>/dev/null`.split("\n")[1]
        guess ? guess.split.first : 'Expenses:generic'
      end
    end
  end
end
