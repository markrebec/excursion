require 'excursion/configuration'

module Excursion
  @@configuration = Excursion::Configuration.new

  def self.configure(&block)
    @@configuration.configure &block
  end

  def self.configuration
    @@configuration
  end
end

require 'excursion/pool'
require 'excursion/helpers'
require 'excursion/railtie'
