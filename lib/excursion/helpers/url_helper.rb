module Excursion
  module Helpers
    class UrlHelper
      attr_reader :application

      def routes
        @application.routes
      end

      def method_missing(meth, *args)
        route = @application.route(route_name_from_method(meth))
        if route.nil?
          super
        else
          if meth.to_s.match(/_url\Z/)
            url_opts = (@application.default_url_options || {}).clone
            url_opts.merge!(args.slice!(args.length-1)) if args.last.is_a?(Hash) #&& args.last.has_key?(:host)
              
            ActionDispatch::Http::URL.url_for(url_opts.merge({path: replaced_path(route, args)}))
          elsif meth.to_s.match(/_path\Z/)
            replaced_path(route, args)
          end
        end
      end

      def respond_to_missing?(meth, include_private=false)
        !@application.route(route_name_from_method(meth)).nil? || super
      end

      protected

      def initialize(app)
        @application = app
      end

      def route_name_from_method(meth)
        meth.to_s.gsub(/_(url|path)\Z/,'').to_sym
      end

      # Very hacky method to replace path parts with values
      #
      # Needs work, particularly around formatting which is basically ignored right now.
      def replaced_path(route, args)
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
