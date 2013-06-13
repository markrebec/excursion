require 'dalli'
require 'excursion/datasources/datasource'
require 'excursion/exceptions/memcache'

module Excursion
  module Datasources
    class Memcache < Datasource

      def read(key)
        @client.get(key.to_s)
      rescue Dalli::RingError => e
        rescue_from_dalli_ring_error(e) && retry
      end
      alias_method :get, :read

      def write(key, value)
        @client.set(key.to_s, value)
      rescue Dalli::RingError => e
        rescue_from_dalli_ring_error(e) && retry
      end
      alias_method :set, :write

      def delete(key)
        @client.delete(key)
      rescue Dalli::RingError => e
        rescue_from_dalli_ring_error(e) && retry
      end
      alias_method :unset, :delete

      protected

      def initialize(server=nil, options={})
        server ||= Excursion.configuration.memcache_server
        raise MemcacheConfigurationError, "You must configure the :memcache datasource with a memcache_server" if server.nil?
        @client = Dalli::Client.new(server, options)
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

        STDERR.puts "Excursion memcache server has gone away! Retrying..."
        sleep 1 # give it a chance to come back
        @dalli_retries += 1
      end
    end
  end
end
