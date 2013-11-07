module Excursion
  module Datastores
    class Datastore
      APP_CLASS = Excursion::Pool::Application

      def app(key)
        APP_CLASS.from_cache(read(key))
      end
      
      def all_apps
        apps = []
        all.delete_if { |k| k.match(/^_.*/) }.values.each do |v|
          apps << APP_CLASS.from_cache(v)
        end
        apps
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
