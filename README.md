# Excursion

Provides a pool of routes into which applications can dump their host information and routing table. Other applications can then utilize application namespaced helper methods for redirecting, etc. between apps. Particularly useful when multiple applications are sharing a database. For example, linking from a user profile on a frontend application to a separate admin or CMS interface (hosted as a separate rails app): `my_admin_app.edit_user_url(@user)`.

### How it works

When an application registers itself with the route pool, a simple hash of config values and route names & paths (the `/users/:user_id/edit` path spec definitions) for that application are dumped into the pool. The datastore for the pool is configurable.

Any other applications using excursion and configured with the same route pool will then have access to the namespaces url helpers for any apps registered with that pool. An application does not have to register itself with the pool to be able to use excursion as a client and utilize other app's namespaced helpers.

The url helpers are automatically included into your controllers and views, and allow you to do things like `admin_app.edit_user_url(@user)` from any of your applications. These helper methods will check the route pool to see if the requested application exists, and will attempt to locate the named route and handle the variable replacement and default url options to generate a url like `http://admin_app.example.com/users/1/edit`.

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
  # You will still be able to use the pool as a client, and will have
  # access to the url helpers for any applications that *are* configured
  # in the pool.
  config.register_app = true # default is true


  # This is a lot like ActionMailer default_url_options. In fact, if
  # you have set those default_url_options already, you can just use
  # them here. You should provide at least a host, port is optional.
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

Excursion will automatically add this application to the route pool on initialization unless you've configured it to behave otherwise. Once an application has been registered with the route pool, any other applications configured with that same route pool will have access to url helpers for that application.

### URL Helpers

The url helpers are available for use in your controllers and views by default, and can be used just like normal url helpers (except they're namespaced to the parent application). So, for example let's take two applications that need to be able to bounce a user back and forth - `AppOne` and `AppTwo`.

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

If you want to make the url helpers available within some other class, you can simply include them in the class:

```ruby
class AppOne::ExampleClass
  include Excursion::Helpers::ApplicationHelper

  def do_something_with_user(user)
    # You can then use the helper methods straight away
    puts app_two.edit_user_url(user)
  end
end

# Or if you need them in a mailer
class MyMailer < ActionMailer::Base
  add_template_helper Excursion::Helpers::ApplicationHelper
end
```

Or you can just use the static helpers, which are globally accessible through `Excursion.url_helpers`:

```ruby
Excursion.url_helpers.app_one.signup_url
Excursion.url_helpers.app_two.root_url
# etc.
```

### Rake Tasks

#### `excursion:register`

Registers this application and it's routes with the configured route pool. This happens automatically on initialization unless you've configured excursion to behave otherwise, but this can be handy to pre-populate the pool on deploy when pushing multiple apps.

#### `excursion:remove`

Removes this application and it's routes from the configured route pool.
