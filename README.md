# Excursion

Provides a pool of routes into which applications can dump their host information and routing table. Other applications can then utilize application namespaced helper methods for redirecting, etc. between apps. Particularly useful when multiple applications are sharing a database. For example, linking from a user profile on a frontend application to a separate admin or CMS interface (hosted as a separate rails app): `my_admin_app.edit_user_url(@user)`.

## Installation

Excursion is written for Rails, which means you should have a Gemfile and be using bundler. To start using excursion, add this to your application Gemfile:

    gem 'excursion'

And run `bundle install` to add it to your bundle.

## Configuration

Create an initializer in `/config/initializers/excursion.rb` for configuration:

    Excursion.configure do |config|
      # This is a lot like ActionMailer.default_url_options
      # You should provide at least a host, port is optional
      config.default_url_options = {host: 'www.example.com', port: 80}
      
      # Example using a shared file
      config.datasource = :file
      config.datasource_file = '/path/to/shared/file'

      # Example using memcache
      # This requires the `dalli` gem!
      config.datasource = :memcache
      config.memcache_server = 'localhost:11211'
    end

That's it. When your application initializes it'll automatically dump it's routes into the configured route pool, and other applications will have access to them (and this application will have access to other app's routes).

As noted in the example, if you want to use memcache for the route pool you'll need the [dalli gem](https://github.com/mperham/dalli), so make sure to add it to your Gemfile:

    gem 'dalli'

## Usage

Once you've configured and launched your applications, you'll have access to the excursion url helpers in your controllers and views. Let's use two applications, `AppOne` and `AppTwo`, as an example.

    # AppOne using a route from AppTwo in a controller action
    class MyController < ApplicationController
      def index
        # do some stuff
        redirect_to app_two.edit_user_url(@user)
      end
    end

    # AppTwo using a route from AppOne in a view
    <%= link_to "logout", app_one.logout_url %>

If you want to make the helper methods available within some other class, you can simply include them in the class:

    class AppOne::ExampleClass
      include Excursion::Helpers::ApplicationHelper

      def do_something_with_user(user)
        # You can then use the helper methods straight away
        puts app_two.edit_user_url(user)
      end
    end

Or you can just use the static helpers, which are globally accessible through `Excursion.url_helpers`:

    Excursion.url_helpers.app_one.signup_url
    Excursion.url_helpers.app_two.root_url
    # etc.
