# Excursion

[![Build Status](https://travis-ci.org/markrebec/excursion.png)](https://travis-ci.org/markrebec/excursion)

Excursion provides a pool of routes into which applications can dump their host information and a basic representation of their routing table. Other applications configured to use the same pool can utilize namespaced url helpers for redirecting, drawing links, etc. between apps. This is extremely useful when multiple applications are sharing a database or, for example, are powered by a shared [rails engine](http://edgeapi.rubyonrails.org/classes/Rails/Engine.html). 

#### Why it's useful

Lets say you have a standalone admin or CMS application running separately from your user-facing frontend application, to manage your content, users and other internal concerns. Or maybe you also have discussion forums, or a knowledge base or help center, all running as a standalone rails applications. These apps would be sharing a database, and would likely be sharing models, authentication and other functionality via gems or a rails engine. 

If you wanted to add a link, from the admin edit user screen, to a user's profile endpoint in the frontend app, you would have to do something like this:

```erb
<%= link_to "user profile", "http://frontend_app.example.com/users/#{@user.username}" %>
```

Maybe you have some default url options setup to help with the host, port, etc., and maybe your `User` model has a `to_param` method defined to return the username and simplify using it in URLs and other places, but it's still not pretty. At the **very best** you're still hardcoding the path, and if that route ever changes in the other application it's unlikely you'll catch it right away for any apps hardcoded like this.

With excursion, once an app has registered itself with the route pool, the above becomes:

```erb
<%= link_to "user profile", frontend_app.user_url(@user) %>
```

If you want to go the other way, and add a link on your user profile pages to ban the user (only for your admins of course!) using an endpoint in the admin app, it's just as easy:

```erb
<%= link_to "ban this user", admin_app.ban_user_url(@user) %>
```

The namespaced url helpers work just like rails built-in helpers, and (using the default configuration) every time an application initializes it will update it's routing table in the pool, so you don't have to worry about maintaining hardcoded paths in your applications. Of course, if you change the **name** of the route, you'll still have to update any calls to the namespaced url helper for that route in any apps that use it (just like you would need to update calls to the standard url helpers within the app where you're making that change). But, when you do make those changes, excursion will complain with a `NoMethodError` just like rails' built-in url helpers would, letting you know what needs to be changed rather than relying on smoke tests or QA to find dead links.

The helper methods are also extremely handy for shared controllers and views - If you've got multiple apps sharing a layout or some partials via an engine or gem, using the namespaced url helpers ensures links will always point to the correct place no matter what app is currently rendering the template.

#### A note about `:format` support

Basically, it's not supported right now. Unfortunately excursion currently does not support passing a format to it's url helpers, and the `:format` path part is stripped completely from the returned url.

The issue is being addressed, and you can take a look at [Issue #1](https://github.com/markrebec/excursion/issues/1) for more details or if you'd like to try to help out.

### How it works

When an application registers itself with the route pool, a simple hash of config values and route names & paths (the `/users/:user_id/edit` path spec definitions) for that application are dumped into the pool.

Any other applications using excursion and configured with the same route pool will then have access to the namespaced url helpers for any apps registered with that pool. An application does not have to register itself with the pool to be able to use excursion as a client and utilize other app's namespaced helpers.

The url helpers are automatically included into your controllers and views, and allow you to do things like `admin_app.edit_user_url(@user)` from any of your applications. These helper methods will check the route pool to see if the requested application exists, and will attempt to locate the named route and handle the variable replacement and default url options to generate a url like `http://admin_app.example.com/users/1/edit`.

## Installation

Excursion is written for Rails, which means you should have a Gemfile and be using bundler. To start using excursion, add this to your application Gemfile:

    gem 'excursion'

If you're planning on using the `:memcache` datastore, you must also add the [dalli](https://github.com/mperham/dalli) gem to your Gemfile:

    gem 'dalli'

And run `bundle install` to add it to your bundle.

If you're planning on using the `:active_record` datastore, you must run the following to install and run the necessary migration after you bundle:

    rails generate excursion:active_record
    rake db:migrate

If you're planning on using the `:active_record_with_memcache` datastore, you must follow the instructions above for both the `:active_record` and `:memcache` datastores.

## Configuration

Create an initializer in `/config/initializers/excursion.rb` for configuration:

**Tip:** If you **are** using a shared rails engine or a gem to power all your apps, you can probably add the execursion dependency **and** the config initializer directly to your engine/gem, as all your apps will almost surely be using the same datastore/pool configuration (since that's sorta the point!).

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


  # You'll need to configure the datastore you'll be using for the
  # route pool if you want to contribute to the pool or use it as
  # a client.
  #
  # Right now the supported types are:
  #   :file - Uses a shared YAML file. Useful for dev environments.
  #   :memcache - Uses a configured memcached server.
  #   :active_record - Uses an ActiveRecord model and a table in your database.
  #   :active_record_with_memcache - Uses the :active_record datastore with the :memcache datastore layered on top.
  
  # Shared File
  config.datastore = :file
  config.datastore_file = '/path/to/shared/file'

  # Memcache
  #
  # Requires the `dalli` gem
  config.datastore = :memcache
  config.memcache_server = 'localhost:11211'

  # ActiveRecord
  #
  # You must run `rails generate excursion:active_record` and `rake db:migrate`
  # in order to generate and run the migration to enable the :active_record datastore.
  config.datastore = :active_record

  # ActiveRecord with Memcache
  #
  # You must run `rails generate excursion:active_record` and `rake db:migrate`
  # in order to generate and run the migration to enable the :active_record datastore.
  #
  # Requires the `dalli` gem
  config.datastore = :active_record_with_memcache
  config.memcache_server = 'localhost:11211'
end
```

That's it. When your application initializes it'll automatically dump it's routes into the configured route pool (unless configured otherwise). Other applications using excursion will have access to this app's routes and this application will have access to other app's routes via the helper methods.

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
```

Or if you need them in a mailer:

```ruby
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

### Rake tasks

#### `excursion:register`

Registers this application and it's routes with the configured route pool. This happens automatically on initialization unless you've configured excursion to behave otherwise, but this can be handy to pre-populate the pool on deploy when pushing multiple apps.

#### `excursion:remove`

Removes this application and it's routes from the configured route pool.

### Testing your application

The one catch with excursion is that it can make functional testing in your apps which depend on each others' routes a bit more difficult. I'm looking at ways to configure excursion for a test environment and have it not raise `NoMethodError` when the application or routes don't exist in the pool, but that can still cause functional tests to fail if they rely on or expect those redirects or links being generated properly.

The easiest way to work with this at the moment is to configure excursion in your test environment to use a shared `:file` datastore that all the apps have access to:

```ruby
Excursion.configure do |config|
  if Rails.env.test?
    config.datastore = :file
    config.datastore_file = '/some/shared/pool'
  else
    # other env configs here
  end
end
```

And pre-populate that test pool by running `rake excursion:register RAILS_ENV=test` from each of your applications prior to running any of their tests.

Alternately, you can add some test helpers or support files that will fill the pool with the necessary routes using your own custom logic before your suite (or even each test if you wanted). To provide an example:

As Part of your checkin/release process for all your apps, you might require dumping routes into a shared pool file, which is then checked in somewhere (maybe into the repo for a gem that all your apps also share). Then, in each of your application's test helpers you can load that file (from wherever you've got it maintained) and dump those routes into the configured excursion pool for your test environment.

### Contributing

If you have a feature or fix you'd like to contribute, please do so by:

1. Fork this repo
2. Create a feature branch
3. Make your changes (be sure to include/update specs as appropriate)
4. Commit and push your changes
5. Create a pull request

#### Running specs

You can run specs with `bundle exec rspec` or using the rake task `bundle exec rake spec`. Because excursion's specs include tests for all the datastores, you'll need to have a memcache server running on `localhost:11211` when running rspec, otherwise the memcache specs will fail.

### Copyright

Copyright (c) 2013 Mark Rebec. See LICENSE for details.
