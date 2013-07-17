module Excursion
  module Pool
    class DummyApplication < Application
      attr_reader :name, :default_url_options

      def route(key)
        @routes.add(key.to_s, journey_route(key.to_s, Rails.application, journey_path("/#{name}/#{key.to_s}"), {required_defaults: []})) if @routes[key.to_sym].nil?
        @routes[key.to_sym]
      end

      def [](key)
        instance_variable_get("@#{key}".to_sym) || nil
      end

      def has_key?(key)
        instance_variable_get("@#{key}".to_sym).nil?
      end
    
    end
  end
end
