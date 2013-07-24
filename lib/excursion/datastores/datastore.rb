module Excursion
  module Datastores
    class Datastore
      

      def app(key)
        Excursion::Pool::Application.from_cache(read(key))
      end
      
      def read(key); end
      alias_method :get, :read
      def write(key, value); end
      alias_method :set, :write
      def delete(key); end
      alias_method :unset, :delete

    end
  end
end
