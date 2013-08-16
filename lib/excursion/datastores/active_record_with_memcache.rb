require 'excursion/datastores/active_record'
require 'excursion/datastores/memcache'

module Excursion
  module Datastores
    class ActiveRecordWithMemcache < Datastore
      
      def read(key)
        value = @cache.read(key)
        return value unless value.nil?
        
        value = @model.read(key)
        @cache.write(key, value) unless value.nil?

        value
      end
      alias_method :get, :read
      
      def write(key, value)
        @model.write(key, value)
        @cache.write(key, value)
      end
      alias_method :set, :write
      
      def delete(key)
        @model.delete(key)
        @cache.delete(key)
      end
      alias_method :unset, :delete

      def all
        hash = @cache.all
        return hash unless hash.nil? || hash.empty?
        @model.all
      rescue Dalli::RingError => e
        rescue_from_dalli_ring_error(e) && retry
      end

      protected

      def initialize(server)
        @model = Excursion::Datastores::ActiveRecord.new
        @cache = Excursion::Datastores::Memcache.new(server)
      end
    
    end
  end
end
