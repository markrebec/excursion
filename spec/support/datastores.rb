module Excursion
  module Specs
    module Datastores
      module Mocks
        SIMPLE_POOL = {
          'key1' => 'value_one',
          'key2' => 'value_two',
          'key3' => 'value_three',
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

        NAMED_ROUTES = {}
        SIMPLE_ROUTES.each do |name,path|
          if Excursion.rails3?
            NAMED_ROUTES[name] = Journey::Route.new(name, Rails.application, Journey::Path::Pattern.new(path), {required_defaults: []})
          elsif Excursion.rails4?
            NAMED_ROUTES[name] = ActionDispatch::Journey::Route.new(name, Rails.application, ActionDispatch::Journey::Path::Pattern.new(path), {required_defaults: []})
          end
        end

        APP_POOL = {
          'simple_app' => SIMPLE_APP
        }
      end
    end
  end
end
