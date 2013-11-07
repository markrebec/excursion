module Excursion
  module Specs
    DUMMY_POOL_FILE = File.expand_path('../../dummy/tmp/spec_pool.yml', __FILE__)
    DUMMY_MEMCACHE_SERVER = 'localhost:11211'

    module Mocks
      def self.journey_route(name, path)
        if Excursion.rails3?
          Journey::Route.new(name, Rails.application, Journey::Path::Pattern.new(path), {required_defaults: []})
        elsif Excursion.rails4?
          ActionDispatch::Journey::Route.new(name, Rails.application, ActionDispatch::Journey::Path::Pattern.new(path), {required_defaults: []})
        end
      end

      SIMPLE_VALUES = {
        'key1' => 'value_one',
        'key2' => 'value_two',
        'key3' => 'value_three',
        '_flag_key' => 'test_flag'
      }

      SIMPLE_APP = {
        name: 'simple_app',
        routes: {
          root: '/',
          example: '/example',
          with_id: '/example/:id'
        },
        default_url_options: {
          host: 'www.example.com',
          port: 3000
        },
        registered_at: Time.now
      }

      SIMPLE_ROUTES = {
        test: '/test',
        example_route: '/abc',
        foo: '/this/is/foo',
        bar: '/and/this/is/bar'
      }

      NAMED_ROUTES = Hash[SIMPLE_ROUTES.collect { |name,path|[name, journey_route(name, path)] }]
      NAMED_ROUTE_COLLECTION = ActionDispatch::Routing::RouteSet::NamedRouteCollection.new
      NAMED_ROUTES.each { |name,route| NAMED_ROUTE_COLLECTION.add(name, route) }

      APP_POOL = {
        '_flag_key' => 'test_flag',
        SIMPLE_APP[:name] => SIMPLE_APP
      }
    end
  end
end
