require 'yaml'
require 'excursion/pool/dummy_application'
require 'excursion/datastores/datastore'

module Excursion
  module Datastores
    class Test < Datastore
      attr_accessor :pool
      
      def app(key)
        Excursion::Pool::DummyApplication.from_cache(read(key))
      end
      
      def all_apps
        apps = []
        all.values.each do |v|
          apps << Excursion::Pool::DummyApplication.from_cache(v)
        end
        apps
      end

      def read(key)
        return unless Excursion.configuration.test_providers.nil? || Excursion.configuration.test_providers.map(&:to_sym).include?(key.to_sym)
        @pool[key.to_sym] ||= Excursion::Pool::DummyApplication.new(key, {default_url_options: {host: 'www.example.com'}}, ActionDispatch::Routing::RouteSet::NamedRouteCollection.new).to_cache
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

      def all
        HashWithIndifferentAccess.new(@pool)
      end

      protected

      def initialize(pool=nil)
        @pool = {}
        @pool = pool.dup unless pool.nil?
      end
    end
  end
end
