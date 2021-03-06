# Excursion

[![Gem Version](https://badge.fury.io/rb/excursion.png)](http://badge.fury.io/rb/excursion)
[![Build Status](https://travis-ci.org/markrebec/excursion.png)](https://travis-ci.org/markrebec/excursion)
[![Code Climate](https://codeclimate.com/github/markrebec/excursion.png)](https://codeclimate.com/github/markrebec/excursion)
[![Coverage Status](https://coveralls.io/repos/markrebec/excursion/badge.png?branch=master)](https://coveralls.io/r/markrebec/excursion?branch=master)
[![Dependency Status](https://gemnasium.com/markrebec/excursion.png)](https://gemnasium.com/markrebec/excursion)


Excursion provides a pool of routes into which applications can dump their host information and a basic representation of their routing table, along with javascript URL helpers and [CORS](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing) configuration to enable cross-origin resource sharing for any of your route endpoints. Other applications configured to use the same route pool can utilize namespaced url helpers for redirecting, drawing links, placing cross-origin XHR requests, etc. between apps. This is extremely useful when multiple applications are sharing a database, authentication, and/or are powered by a shared [rails engine](http://edgeapi.rubyonrails.org/classes/Rails/Engine.html). 

#### Why it's useful

Lets say you have a standalone admin or CMS application running separately from your user-facing frontend application to manage your content, users and other internal concerns. Or maybe you also have discussion forums, a blog, or maybe a knowledge base or help center, all running as a standalone rails applications. These apps would be sharing a database, and would likely be sharing models, authentication/cookies/sessions and other functionality via common gems.

If you wanted to add a link from the admin edit user screen to view a user's profile in the frontend app, you might have to do something like this:

```erb
<%= link_to "view profile", "http://frontend_app.example.com/users/#{@user.username}" %>
```

Maybe you have some default url options setup to help with the host, port, etc., and maybe your `User` model has a `to_param` method defined to return the username and simplify using it in URLs and other places, but it's still not pretty. At the **very best** you're still hardcoding the path, and if that route ever changes in the other application it's unlikely you'll catch it right away for any apps hardcoded like this.

With excursion, once an app has registered itself with the route pool, the above becomes:

```erb
<%= link_to "view profile", frontend_app.user_url(@user) %>
```

If you want to go the other way, and add a link on your user profile pages to ban the user (only for your admins of course!) using an endpoint in the admin app, it's just as easy:

```erb
<%= link_to "ban this user", admin_app.ban_user_url(@user) %>
```

The namespaced url helpers work just like rails built-in helpers, and (using the default configuration) every time an application initializes it will update it's routing table in the pool, so you don't have to worry about maintaining hardcoded paths in your applications. 

Of course, if you change the **name** of the route you'll still have to update any calls to the namespaced `*_url` helpers for that route wherever you're using it, just like you would need to update calls to rails' built-in `*_url` helpers - but when you do make those changes, excursion will complain with a `NoMethodError` just like rails' built-in url helpers would, letting you know what needs to be changed rather than relying on smoke tests or QA to find dead links.

The helper methods are also extremely handy for shared controllers and views. If you've got multiple apps sharing a layout or some templates or partials via a common gem, using the namespaced url helpers within those shared templates ensures links will always point to the correct place no matter what app is currently rendering them.

##### CORS support and javascript helpers

Excursion also provides support for two additional common concerns when navigating cross-application routes: CORS requests and javascript url helpers.  You may optionally include the excursion javascript helpers in your templates, which will provide you with url helper methods in your client-side javascript for all applications in the route pool. And if you're using the javascript helpers, it's likely you'll be making cross-origin XHR requests, so excursion also includes optional support for CORS headers and `OPTIONS` requests, with configuration options to control access to your resources.

#### A note about `:format` support

Basically, it's not supported right now.

The issue is being addressed, and you can take a look at [Issue #1](https://github.com/markrebec/excursion/issues/1) for more details or if you'd like to try to help out.

### How it works

When an application registers itself with the route pool, a simple hash of config values and route names & paths (the `/users/:user_id/edit` path spec definitions) for that application are dumped into the pool.

Any other applications using excursion and configured with the same route pool will then have access to the namespaced url helpers for any apps registered with that pool. An application does not have to register itself with the pool to be able to use excursion as a client and utilize other app's namespaced helpers.

The url helpers are automatically included into your controllers and views, and allow you to do things like `admin_app.edit_user_url(@user)` from any of your applications. These helper methods will check the route pool to see if the requested application exists, and will attempt to locate the named route and handle the variable replacement and default url options to generate a url like `http://admin_app.example.com/users/1/edit`.

## Installation

Excursion is written for Rails and requires `rails >= 3.2.0`, which means you should have a Gemfile and be using bundler. To start using excursion, add this to your application Gemfile:

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


  # CORS Configuration
  config.enable_cors = true                                                                 # enables cross-origin resource sharing for this app (default false)
  config.cors_whitelist = :pool                                                             # whitelist for allowing cors for specific domains (defaults to only allow apps in the pool)
  config.cors_blacklist = nil                                                               # blacklist for denying cors for specific domains
  config.cors_allow_methods = %w(POST PUT PATCH GET DELETE)                                 # list of allowed cors request methods (Access-Control-Allow-Methods)
  config.cors_allow_headers = %w(origin content-type accept x-requested-with x-csrf-token)  # list of allowed cors request headers (Access-Control-Allow-Headers)
  config.cors_allow_credentials = true                                                      # allow credentials with cors requests (Access-Control-Allow-Credentials)
  config.cors_max_age = 1728000                                                             # cors max age (Access-Control-Max-Age)
end
```

That's it. When your application initializes it'll automatically dump it's routes into the configured route pool (unless configured otherwise). Other applications using excursion will have access to this app's routes and this application will have access to other app's routes via the helper methods.

## Usage

Excursion will automatically add this application to the route pool on initialization unless you've configured it to behave otherwise. Once an application has been registered with the route pool, any other applications configured with that same route pool will have access to url helpers for that application.

### URL Helpers

#### Controllers & Views

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

#### Other Classes

If you want to make the url helpers available within some other class, you can simply include them in the class:

```ruby
class AppOne::ExampleClass
  include Excursion::Builders::ApplicationBuilder

  def do_something_with_user(user)
    # You can then use the helper methods straight away
    puts app_two.edit_user_url(user)
  end
end
```

#### Mailers

Or if you need them in a mailer:

```ruby
class MyMailer < ActionMailer::Base
  add_template_helper Excursion::Builders::ApplicationBuilder
end
```

#### Global Helpers

Or you can just use the static helpers, which are globally accessible through `Excursion.url_helpers`:

```ruby
Excursion.url_helpers.app_one.signup_url
Excursion.url_helpers.app_two.root_url
# etc.
```

### JavaScript Helpers

Excursion also implements javascript helpers which you can use to provide access to URL helper methods within your frontend javascript. This is currently a prototype, mostly just because it needs to be cleaned up a bit, but it works well enough to be used in production.

To use the javascript helpers, you'll need to include the `excursion.js` javascript file and then either include the `excursion/pool.js` file **or** call the `render_excursion_javascript_helpers` helper method somewhere within your layout. The former will automatically render your route pool into the `pool.js` file when it is included in your layout, while the latter will dump your route pool directly into your layout and load it that way.

#### With the pool.js asset file

The simplest way to include the required javascript and your route pool is to require them in your `application.js` file:

```javascript
//= require excursion
//= require excursion/pool
//= require_tree .
```

This will automatically provide your client-side javascript with the `Excursion` object with helper methods defined for each application in your route pool.

**A note about asset caching**

The `excursion/pool.js` asset file is dynamic and loads your route pool on render. But (depending on your environment configuration) rails will automatically cache your assets and serve those cached versions. This means if you were to add a new application or route to your pool and then reloaded the page, you'd still be loading the cached route pool javascript file. This is generally only a problem in development environments since you're actively making changes, and because assets for production should be precompiled anyway.

One workaround is to ensure you clear your asset cache (usually `your_app/tmp/cache/assets`) whenever you update the route pool. 

Alternately, adding the following settings to your `/config/environments/development.rb` should prevent asset caching altogether, but may slow down performance in your development environment if you've got a large number of assets:

```ruby
  config.assets.cache_store = :null_store  # Disables the Asset cache
```

#### With the view helper

If you prefer, you can include the javascript route pool directly in your layout instead of using the pool asset file. This will dump a script tag into your layout containing the javascript route pool.

You will need to include the core `excursion.js` library either directly in your layout, or in your `application.js` file:

```javascript
//= require excursion
//= require_tree .
```

In order to render your routes into the layout so they're available, use the `render_excursion_javascript_helpers` method. I recommend calling it somewhere near the end of your layout:

```erb
<html>
<head>...</head>
<body>
  ...
  <%= render_excursion_javascript_helpers %>
</body>
</html>
```

#### Javascript helper usage

You can then use the named helper methods to generate URLs and paths within your client-side javascript:

```javascript
Excursion.app_one.root_url()        // http://app_one.local
Excursion.app_two.user_url('mark')  // http://app_two.local/users/mark
Excursion.app_two.user_path('mark') // /users/mark
```

#### Security concerns

Yes. Using these javascript helpers means your routes will be made available to client-side javascript, which means the route pool itself is visible to anyone (with a little bit of effort). In some cases this may be a security concern, but for the most part your routes are "public" by definition - they're the public entry point into your application. Thinking you are "hiding a URL" just because the outside world doesn't have access to your `config/routes.rb` file is by no means a safeguard, and it is the responsibility of authorization and access control in your app to prevent unwanted access to controller actions.

With all that said, I have taken some small steps to obfuscate the raw route pool a little bit by base64 encoding the pool so that it's not just a clear JSON hash for all the world to see. There are also plans to add some whitelist/blacklist/regex support for including or excluding routes and applications.

### CORS

In order to take advantage of the CORS support provided by excursion, you'll need to configure the CORS-related settings in the configuration section above and mount the `OPTIONS` routes at the top of your `config/routes.rb` file like this:

```ruby
MyApp::Application.routes.draw do
  mount Excursion::Engine => '/'
  ...
end
```

This will provide you with the following route for CORS preflight `OPTIONS` requests, as well as return the appropriate CORS response headers for the actual request:

```
OPTIONS /*path(.:format) excursion#cors_preflight
```

### Rake tasks

#### `excursion:register`

Registers this application and it's routes with the configured route pool. This happens automatically on initialization unless you've configured excursion to behave otherwise, but this can be handy to pre-populate the pool on deploy when pushing multiple apps.

#### `excursion:remove`

Removes this application and it's routes from the configured route pool.


### Testing your application

The one catch with excursion is that it can make functional testing in your apps which depend on each other's routes a bit more difficult. Initially, when running tests with excursion enabled in your application, you would get swamped with `NoMethodError` errors due to your route pool not being populated in the test environment.

The addition of a `:test` datastore and `DummyApplication` class, which will respond to **any** helper call with a predictable url path (which can be programmed against) **when the application/route does not exist in the pool** has helped remedy this.

If you configure your test environment to use the `:test` datastore, you should be able to get your functional tests passing, although there is still one catch: if you do not pre-populate the pool with your routes, the dummy application will respond with predictable dummy url paths as described above.  So, for example, if you were to call `cats_url` and the named route for `cats` is **not** pre-populated into excursion, you'll end up with a URL like `http://www.example.com/app_name/cats` (as opposed to a real world url path like `http://my.appserver.com/cats`).

Below is an example of configuring the `:test` datastore for your test environment in a config initializer. In this case, we're also not registering our app, but you can register it with the pool if you want to test a real world result for any specific excursion url helpers. It is also a good idea to configure `test_providers`, which should be a (array) list of the applications you would expect to be available in the pool. This helps prevent the `:test` datastore from intercepting calls it maybe shouldn't when running things like request and functional tests.

```ruby
Excursion.configure do |config|
  if Rails.env.test?
    config.datastore = :test
    config.test_providers = [:app_one, :other_app]
    config.register_app = false
  else
    # other env configs here
  end
end
```

You may also add support code to your test/spec helpers to either register your application(s) or populate your `:test` datastore with a static set of dummy data (maybe imported from a yaml file or some other data source).

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
