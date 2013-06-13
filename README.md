# Excursion

Provides a pool of routes into which applications can dump their host information and routing table. Other applications can then utilize application namespaced helper methods for redirecting, etc. between apps. Particularly useful when multiple applications are sharing a database. For example, linking from a user profile on a frontend application to a separate admin or CMS interface (hosted as a separate rails app): `my_admin_app.edit_user_url(@user)`.

## Installation

Excursion is written for Rails, which means you should have a Gemfile and be using bundler. To start using excursion, add this to your application Gemfile:

    gem 'excursion'

And run `bundle install` to add it to your bundle.

## Configuration

Create an initializer in `/config/initializers/excursion.rb` for configuration:

```ruby
Excursion.configure do |config|
  
  # This controls whether this application is automatically added to
  # the route pool on initialization.
  #
  # If this is false, you will either have to register this app using
  # the rake task or Excursion::Pool.register_application(Rails.application)
  # to add it to the pool and make it available to other apps using
  # excursion. Otherwise this app's routes won't be added to the pool.
  #
  # You will still be able to use the helper methods for any applications
  # that *are* configured in the pool.
  config.register_app = true # default is true


  # This is a lot like ActionMailer.default_url_options. You should
  # provide at least a host, port is optional.
  #
  # If this application will not be contributing routes to the pool,
  # this can be left unconfigured.
  config.default_url_options = {host: 'www.example.com', port: 80}


  # You'll need to configure the datasource you'll be using for the
  # route pool if you want to contribute to the pool or use it as
  # a client.
  #
  # Right now the two supported types are a yaml :file or :memcache, but 
  # datasources are planned for :redis and :active_record as well.

  # Example using a shared file
  config.datasource = :file
  config.datasource_file = '/path/to/shared/file'

  # Example using memcache
  # This requires the `dalli` gem!
  config.datasource = :memcache
  config.memcache_server = 'localhost:11211'
end
```

That's it. When your application initializes it'll automatically dump it's routes into the configured route pool (unless configured otherwise). Other applications using excursion will have access to this app's routes and this application will have access to other app's routes via the helper methods.

As noted in the above examples, using memcache for the route pool requires the [dalli gem](https://github.com/mperham/dalli), so make sure to add it to your Gemfile:

    gem 'dalli'

## Usage

Once you've configured and launched your applications, you'll have access to the excursion url helpers in your controllers and views. Let's use two applications, `AppOne` and `AppTwo`, as an example.

```ruby
# AppOne using a route from AppTwo in a controller action
class MyController < ApplicationController
  def index
    # do some stuff
    redirect_to app_two.edit_user_url(@user)
  end
end

# AppTwo using a route from AppOne in a view
<%= link_to "logout", app_one.logout_url %>
```

If you want to make the helper methods available within some other class, you can simply include them in the class:

```ruby
class AppOne::ExampleClass
  include Excursion::Helpers::ApplicationHelper

  def do_something_with_user(user)
    # You can then use the helper methods straight away
    puts app_two.edit_user_url(user)
  end
end
```

Or you can just use the static helpers, which are globally accessible through `Excursion.url_helpers`:

```ruby
Excursion.url_helpers.app_one.signup_url
Excursion.url_helpers.app_two.root_url
# etc.
```
