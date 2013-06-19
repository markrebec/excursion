require 'excursion/datastores/datastore'
require 'excursion/exceptions/active_record'

module Excursion
  module Datastores
    class ActiveRecord < Datastore
      
      def model_find(key)
        return @model.find_by(key: key) if Excursion.rails4?
        return @model.find_by_key(key) if Excursion.rails3?
      end

      def read(key)
        model_find(key).value
      rescue
        nil
      end
      alias_method :get, :read
      
      def write(key, value)
        written = model_find(key)
        if written.nil?
          written = @model.create key: key, value: value
        else
          written.update value: value
        end
        written.value
      end
      alias_method :set, :write
      
      def delete(key)
        deleted = model_find(key)
        return nil if deleted.nil?
        deleted.destroy
        deleted.value
      end
      alias_method :unset, :delete

      protected

      def initialize
        @model = Excursion::RoutePool
      end
    
    end
  end
end
