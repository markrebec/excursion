module Excursion
  module Datasources
    class Datasource
      
      def read(key); end
      alias_method :get, :read
      def write(key, value); end
      alias_method :set, :write
      def delete(key); end
      alias_method :unset, :delete

    end
  end
end
