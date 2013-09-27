module Excursion
  module Pool
    class DSL

      def self.block_eval(app=nil, &block)
        @application = app.is_a?(Excursion::Pool::Application) ? app : Excursion::Pool::Application.new('', {})
        instance_eval &block if block_given?
        @application
      end

      def self.name(name_str)
        @application.name = name_str
      end

      def self.default_url_options(url_options)
        @application.default_url_options = url_options
      end

      def self.routes(route_hash)
        @application.routes = route_hash
      end

      def self.route(name, path)
        @application.add_route(name.to_sym, path)
      end
    end
  end
end
