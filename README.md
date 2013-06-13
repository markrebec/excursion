# Excursion

Provides a pool of routes into which applications can dump their host information and routing table. Other applications can then utilize application namespaced helper methods for redirecting, etc. between apps. Particularly useful when multiple applications are sharing a database. For example, linking from a user profile on a frontend application to a separate admin or CMS interface (hosted as a separate rails app): `my_admin_app.edit_user_url(@user)`.

## Installation

Excursion is written for Rails, which means you should have a Gemfile and be using bundler. To start using excursion, add this to your application Gemfile:

    gem 'excursion'

And run `bundle install` to add it to your bundle.

Create an initializer in `/config/initializers/excursion.rb` for configuration:

    Excursion.configure do |config|
      config.datasource = :file # only :file is supported right now
      config.datasource_file = '/path/to/shared/file'
      config.default_url_options = {host: 'www.example.com', port: 80} # you should provide a host, port is optional
    end

That's it. When your application initializes it'll automatically dump it's routes into the route pool, and other applications will have access to them (and this application will have access to other app's routes).

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
