module Excursion
  module Builders
    module ApplicationBuilder
      
      # Returns an Excursion::Builders::UrlBuilder if the app exists in the route pool.
      #
      # Raises an exception if the requested app is not in the route pool.
      def excursion(app_name)
        raise NotInPool, "Application is not registered in the excursion route pool: '#{app_name}'" unless app_exists?(app_name)
        url_builder app_name
      end

      def method_missing(meth, *args)
        super
      rescue NoMethodError => e
        call_excursion meth.to_s
      end

      def respond_to_missing?(meth, include_private=false)
        app_exists?(meth.to_s) || super
      end

      protected

      def app_exists?(app_name)
        !excursion_app(app_name).nil?
      end

      def excursion_app(app_name)
        Pool.application(app_name)
      end
      
      def call_excursion(app_name)
        excursion app_name
      rescue NotInPool => e
        raise e unless Excursion.configuration.suppress_errors
        StubBuilder.new app_name
      end

      def url_builder(app_name)
        return Builders.builder(app_name) unless Builders.builder(app_name).nil?
        Builders.register_builder UrlBuilder.new(app_name)
      end

    end
  end
end
