require 'logcabin'
require 'libledger'

##
# This module provides a unified interface for pulling accountig transactions
module Burglar
  class << self
    ##
    # Insert a helper .new() method for creating a new Heist object

    def new(*args)
      self::Heist.new(*args)
    end

    def modules
      @modules ||= LogCabin.new(load_path: load_path(:modules))
    end

    def helpers
      @helpers ||= LogCabin.new(load_path: load_path(:helpers))
    end

    def extra_dep(name, dep)
      require dep
    rescue LoadError
      raise("The #{name} module requires the #{dep} gem")
    end

    private

    def gem_dir
      Gem::Specification.find_by_name('burglar').gem_dir
    end

    def load_path(type)
      File.join(gem_dir, 'lib', 'burglar', type.to_s)
    end
  end
end

require 'burglar/version'
require 'burglar/heist'
require 'burglar/bank'
