module Excursion
  module Helpers
    class UrlHelper
      attr_reader :application

      def routes
        @application.routes
      end

      def method_missing(meth, *args)
        if meth.to_s.match(/\A(#{routes.collect { |name,route| name }.join("|")})_(url|path)\Z/)
          route = routes.get($1.to_sym)

          url_opts = @application.default_url_options.clone
          url_opts.merge!(args.slice!(args.length-1)) if args.last.is_a?(Hash) #&& args.last.has_key?(:host)
            
          return ActionDispatch::Http::URL.url_for(url_opts.merge({path: replaced_path(route, args)}))
          
          # This stuff is being deprecated.
          # We're transitioning towards using our custom path replacement and the uniform call to the base url_for method.

          #if Excursion.rails4?
            #ActionDispatch::Routing::RouteSet::NamedRouteCollection::UrlHelper.create(route, url_opts).call(Rails.application.routes, args)
          #elsif Excursion.rails3?
            # Playing with getting Rails3 working
            #mapping = ActionDispatch::Routing::Mapper::Mapping.new(routes, {}, routes.get($1.to_sym).path.spec.to_s.dup, {:controller => 'dummy', :action => 'dummy'})
            #puts mapping.send(:instance_variable_get, :@path)
          #end
        else
          super
        end
      end

      def respond_to_missing?(meth, include_private=false)
        meth.to_s.match(/\A(#{routes.collect { |name,route| name }.join("|")})_(url|path)\Z/) || super
      end

      protected

      def initialize(app)
        @application = app
      end

      # Very hacky method to replace path parts with values
      #
      # Needs work, particularly around formatting which is basically ignored right now.
      def replaced_path(route, args)
        path = route.path.spec.to_s.dup

        route.required_parts.zip(args) do |part, arg|
          path.gsub!(/(\*|:)#{part}/, Journey::Router::Utils.escape_fragment(arg.to_param))
        end

        path.gsub!(/\(\.:format\)/, '') # This is really gross, and :format should actually be supported
        path
      end
    end
  end
end
