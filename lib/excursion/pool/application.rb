module Excursion
  module Pool
    class Application
      attr_reader :name, :default_url_options

      def self.from_cache(cached)
        new(cached[:name], cached)
      end

      def route(key)
        routes[key.to_sym]
      end

      def routes
        @routes ||= ActionDispatch::Routing::RouteSet::NamedRouteCollection.new
      end

      def routes=(routes)
        return @routes = routes if routes.is_a?(ActionDispatch::Routing::RouteSet::NamedRouteCollection)
        raise ArgumentError, 'routes must be a Hash or NamedRouteCollection' unless routes.is_a?(Hash)
        @routes = ActionDispatch::Routing::RouteSet::NamedRouteCollection.new
        routes.each do |name, route|
          @routes.add(name, route)
        end
      end

      def set_routes(routes)
        self.routes = routes
      end

      def to_cache
        {
          name: @name,
          routes: Hash[routes.map { |name, route| [name.to_sym, route.path.spec.to_s] }],
          default_url_options: @default_url_options,
          registered_at: @registered_at
        }
      end

      def from_cache(cached)
        @routes = routes_from_cache(cached[:routes]) if cached.has_key?(:routes)
        @default_url_options = cached[:default_url_options]
        @registered_at = (Time.at(cached[:registered_at]) rescue Time.now)
      end
      
      protected

      def initialize(name, config, routes=nil)
        @name = name
        from_cache(config)
        set_routes(routes) unless routes.nil?
      end

      def routes_from_cache(routes)
        collection = ActionDispatch::Routing::RouteSet::NamedRouteCollection.new
        routes.each do |name, path|
          collection.add(name, journey_route(name, Rails.application, journey_path(path), {required_defaults: []}))
        end
        collection
      end
      
      def journey_route(name, app, path, options)
        journey_route_class.new(name, app, path, options)
      end

      def journey_route_class
        if Excursion.rails3?
          Journey::Route
        elsif Excursion.rails4?
          ActionDispatch::Journey::Route
        end
      end
      
      def journey_path(path)
        journey_path_class.new(path)
      end

      def journey_path_class
        if Excursion.rails3?
          Journey::Path::Pattern
        elsif Excursion.rails4?
          ActionDispatch::Journey::Path::Pattern
        end
      end

    
    end
  end
end
