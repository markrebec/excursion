module Excursion
  module Helpers
    class ApplicationHelper

      def routes
        @application.routes
      end

      def method_missing(meth, *args)
        if meth.to_s.match(/\A(#{routes.collect { |name,route| name }.join("|")})_(url|path)\Z/)
          ActionDispatch::Routing::RouteSet::NamedRouteCollection::UrlHelper.create(routes.get($1.to_sym), @application.default_url_options).call(Rails.application.routes, args)
        else
          super
        end
      end

      protected

      def initialize(app)
        @application = app
      end
    end
  end
end
