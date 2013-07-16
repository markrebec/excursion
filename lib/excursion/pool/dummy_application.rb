module Excursion
  module Pool
    class DummyApplication < Application
      attr_reader :name, :default_url_options

      def route(key)
        @routes.add(key.to_s, journey_route(key.to_s, Rails.application, journey_path("/#{name}/#{key.to_s}"), {required_defaults: []})) if @routes[key.to_sym].nil?
        @routes[key.to_sym]
      end
    
    end
  end
end
