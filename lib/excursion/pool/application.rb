module Excursion
  module Pool
    class Application
      attr_reader :name, :default_url_options

      def self.from_cache(cached)
        new.from_cache(cached)
      end

      def route(key)
        routes[key.to_sym]
      end

      def routes
        @routes ||= ActionDispatch::Routing::RouteSet::NamedRouteCollection.new
      end

      def routes=(routes)
        @routes = ActionDispatch::Routing::RouteSet::NamedRouteCollection.new
        routes.each do |name, route|
          @routes.add(name, route)
        end
      end

      def set_routes(routes)
        self.routes = routes
        self
      end

      def to_cache
        {name: @name,
         routes: Hash[routes.map { |name, route| [name.to_sym, route.path.spec.to_s] }],
         default_url_options: @default_url_options,
         registered_at: @registered_at
        }
      end

      def routes_from_cache(routes)
        collection = ActionDispatch::Routing::RouteSet::NamedRouteCollection.new
        routes.each do |name, path|
          collection.add(name, ActionDispatch::Journey::Route.new(name, Rails.application, ActionDispatch::Journey::Path::Pattern.new(path), {required_defaults: []}))
        end
        collection
      end

      def from_cache(cached={})
        @name = cached[:name] # required
        @routes = routes_from_cache(cached[:routes]) if cached.has_key?(:routes)
        @default_url_options = cached[:default_url_options]
        @registered_at = (Time.at(cached[:registered_at]) rescue Time.now)
        self
      end
      
      protected

      def initialize(config={}, routes={})
        from_cache(config).set_routes(routes)
      end
    end
  end
end
