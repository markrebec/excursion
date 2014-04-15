module Excursion
  module Builders
    class StubBuilder
      attr_accessor :app_name
      
      def method_missing(meth, *args)
        if meth.to_s.match(/_(url|path)\Z/)
          requested_route = {
            application: app_name,
            route: meth.to_s.gsub(/_(url|path)\Z/, ''),
            args: args
          }
          requested_route
          # save the requested route in a session? cookie?
          # return the default unknown/stubbed route
          #ActionDispatch::Http::URL.url_for(path: Excursion::Engine.routes.named_routes[:excursion_route_not_found].path, only_path: true)
          Excursion::Engine.routes.named_routes[:excursion_route_not_found].path.to_s
        else
          super
        end
      end

      def respond_to_missing?(meth, include_private=false)
        meth.to_s.match(/_(url|path)\Z/) || super
      end

      protected

      def initialize(app_name)
        @app_name = app_name
      end
    
    end
  end
end
