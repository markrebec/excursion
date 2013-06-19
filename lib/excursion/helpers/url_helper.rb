module Excursion
  module Helpers
    class UrlHelper
      attr_reader :application

      def routes
        @application.routes
      end

      def method_missing(meth, *args)
        if meth.to_s.match(/\A(#{routes.collect { |name,route| name }.join("|")})_(url|path)\Z/)
          if Excursion.rails4?
            ActionDispatch::Routing::RouteSet::NamedRouteCollection::UrlHelper.create(routes.get($1.to_sym), @application.default_url_options).call(Rails.application.routes, args)
          elsif Excursion.rails3?
            # Playing with getting Rails3 working
            #mapping = ActionDispatch::Routing::Mapper::Mapping.new(routes, {}, routes.get($1.to_sym).path.spec.to_s.dup, {:controller => 'dummy', :action => 'dummy'})
            #puts mapping.send(:instance_variable_get, :@path)
            ActionDispatch::Http::URL.url_for(@application.default_url_options.merge({path: replaced_path(routes.get($1.to_sym), args)}))
          end
        else
          super
        end
      end

      protected

      def initialize(app)
        @application = app
      end

      # Playing with getting Rails3 working
      def replaced_path(route, args)
        path = route.path.spec.to_s.dup # ActionDispatch::Routing::Mapper.normalize_path(route.path.spec.to_s.dup)

        route.required_parts.zip(args) do |part, arg|
          path.gsub!(/(\*|:)#{part}/, Journey::Router::Utils.escape_fragment(arg.to_param))
        end

        path.gsub!(/\(\.:format\)/, '') # This is really gross, and :format should actually be supported
        path
      end
    end
  end
end
