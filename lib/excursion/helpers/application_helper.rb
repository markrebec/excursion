module Excursion
  module Helpers
    class ApplicationHelper

      def routes
        @application.routes
      end

      def method_missing(meth, *args)
        if meth.to_s.match(/\A(#{routes.keys.join("|")})_(url|path)/)
          routes[$1.to_sym] || super
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
