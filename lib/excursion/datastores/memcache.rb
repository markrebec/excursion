require 'dalli'
require 'excursion/datastores/datastore'
require 'excursion/exceptions/memcache'

module Excursion
  module Datastores
    class Memcache < Datastore
      REGISTERED_KEYS = 'registered_keys'

      def read(key)
        @client.get(key.to_s)
      rescue Dalli::RingError => e
        rescue_from_dalli_ring_error(e) && retry
      end
      alias_method :get, :read

      def write(key, value)
        value if @client.set(key.to_s, value) && @client.set(REGISTERED_KEYS, (registered_keys << key.to_s).join(','))
      rescue Dalli::RingError => e
        rescue_from_dalli_ring_error(e) && retry
      end
      alias_method :set, :write

      def delete(key)
        regd_keys = registered_keys
        regd_keys.delete(key.to_s)
        value = @client.get(key.to_s)
        value if @client.delete(key.to_s) && @client.set(REGISTERED_KEYS, regd_keys.join(','))
      rescue Dalli::RingError => e
        rescue_from_dalli_ring_error(e) && retry
      end
      alias_method :unset, :delete

      def all
        hash = HashWithIndifferentAccess.new
        registered_keys.each { |key| hash[key.to_s] = @client.get(key.to_s) }
        hash
      rescue Dalli::RingError => e
        rescue_from_dalli_ring_error(e) && retry
      end

      protected

      def initialize(server)
        raise MemcacheConfigurationError, "Memcache server cannot be nil" if server.nil? || server.to_s.empty?
        @client = Dalli::Client.new(server, {namespace: "excursion"})
      end

      def registered_keys
        @client.get(REGISTERED_KEYS).split(',')
      rescue
        []
      end

      # TODO if we're using memcache, and the server goes away, it might be a good idea
      # to make sure to re-register this app in the pool when it comes back, just in case
      # the server crashed and the pool is lost.
      def rescue_from_dalli_ring_error(e)
        @dalli_retries ||= 0
        
        if @dalli_retries >= Excursion.configuration.retry_limit
          retries = @dalli_retries
          @dalli_retries = 0
          raise MemcacheServerError, "Excursion memcache server is down! Retried #{retries} times."
        end

        #STDERR.puts "Excursion memcache server has gone away! Retrying..."
        sleep 1 # give it a chance to come back
        @dalli_retries += 1
      end
    end
  end
end
