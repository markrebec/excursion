module Excursion
  module Builders
    class UrlBuilder

      def application
        Excursion::Pool.application(@appname)
      end

      def routes
        application.routes
      end

      def url_for(route, *args)
        ActionDispatch::Http::URL.url_for(route_options(route, *args))
      end

      def method_missing(meth, *args)
        route = application.route(route_name_from_method(meth))
        if route
          if meth.to_s.match(/_url\Z/)
            url_for(route, *args)
          elsif meth.to_s.match(/_path\Z/)
            replaced_path(route, *args)
          end
        else
          super
        end
      end

      def respond_to_missing?(meth, include_private=false)
        !application.route(route_name_from_method(meth)).nil? || super
      end

      protected

      def initialize(app_name)
        @appname = app_name
      end

      def route_options(route, *args)
        opts = args.extract_options!
        application.default_url_options.merge(opts).merge({path: replaced_path(route, *args)})
      end

      def route_name_from_method(meth)
        meth.to_s.gsub(/_(url|path)\Z/,'').to_sym
      end

      # Very hacky method to replace path parts with values
      #
      # Needs work, particularly around formatting which is basically ignored right now.
      def replaced_path(route, *args)
        path = route.path.spec.to_s.dup

        route.required_parts.zip(args) do |part, arg|
          path.gsub!(/(\*|:)#{part}/, journey_utils_class.escape_fragment(arg.to_param))
        end

        path.gsub!(/\(\.:format\)/, '') # This is really gross, and :format should actually be supported
        path
      end

      def journey_utils_class
        if Excursion.rails3?
          Journey::Router::Utils
        elsif Excursion.rails4?
          ActionDispatch::Journey::Router::Utils
        end
      end
    end
  end
end
