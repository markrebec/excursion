require 'yaml'
require 'excursion/pool/dummy_application'
require 'excursion/datastores/datastore'

module Excursion
  module Datastores
    class Test < Datastore
      attr_accessor :pool

      def read(key)
        @pool[key.to_sym] ||= Excursion::Pool::DummyApplication.new(key, {host: 'test.local'}, ActionDispatch::Routing::RouteSet::NamedRouteCollection.new)
      end
      alias_method :get, :read
      
      def write(key, value)
        @pool[key.to_sym] = value
      end
      alias_method :set, :write

      def delete(key)
        @pool.delete(key.to_sym)
      end
      alias_method :unset, :delete

      protected

      def initialize(pool=nil)
        @pool = {}
        @pool = pool.dup unless pool.nil?
      end
    end
  end
end
