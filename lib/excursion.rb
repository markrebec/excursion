require 'excursion/exceptions'
require 'excursion/configuration'

module Excursion
  @@configuration = Excursion::Configuration.new

  def self.configure(&block)
    @@configuration.configure &block
  end

  def self.configuration
    @@configuration
  end
  
  def self.rails3?
    Rails::VERSION::MAJOR == 3
  end
  
  def self.rails4?
    Rails::VERSION::MAJOR == 4
  end
end

require 'excursion/route_pool'
require 'excursion/pool'
require 'excursion/helpers'
require 'excursion/engine'
require 'excursion/railtie'
