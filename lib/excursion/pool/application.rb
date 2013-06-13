module Excursion
  module Pool
    class Application
      attr_accessor :name

      def self.from_cache(args)
        new.from_cache(args)
      end

      def route(key)
        routes[key.to_sym]
      end

      def routes
        @routes ||= {}
      end


      def routes=(routes)
        @routes = routes
      end

      def set_routes(routes)
        self.routes = routes
        self
      end

      def to_cache
        {name: @name,
         routes: routes,
         host: @host,
         port: @port,
         registered_at: @registered_at
        }
      end

      def from_cache(args={})
        @name = args[:name] # required
        @routes = args[:routes] || {}
        @host = args[:host] || 'localhost'
        @port = args[:port] || 3000
        @registered_at = (Time.at(args[:registered_at]) rescue Time.now)
        self
      end
      
      protected

      def initialize(config={}, routes={})
        from_cache(config.merge(routes: routes))
      end
    end
  end
end
