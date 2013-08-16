module Excursion
  module Datastores
    class Datastore
      

      def app(key)
        Excursion::Pool::Application.from_cache(read(key))
      end
      
      def all_apps
        app_hash = HashWithIndifferentAccess.new
        all.each do |k,v|
          app_hash[k.to_sym] = Excursion::Pool::Application.from_cache(v)
        end
      end
      
      def read(key); end
      alias_method :get, :read
      def write(key, value); end
      alias_method :set, :write
      def delete(key); end
      alias_method :unset, :delete
      def all; end

    end
  end
end
