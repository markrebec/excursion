(function() {

  var Application = function(app) {
    for (prop in app) {
      this[prop] = app[prop];
    }

    for (route in this.routes) {
      (function(thisApp) {
        var routeName = route;
        var path = thisApp.routes[routeName];
        var parts = path.match(/(\(\.)?:[a-z0-9_]+\)?/gi);
        thisApp[routeName + '_path'] = function() {
          var replaced = path;

          if (arguments.length == 1 && typeof arguments[0] == 'object') {
            var args = arguments[0];
          } else {
            var args = arguments;
          }
          
          for (p in parts) {
            if (parts[p] == '(.:format)' && !args[p]) {
              replaced = replaced.replace(parts[p], '');
            } else {
              replaced = replaced.replace(parts[p], args[p]);
            }
          }

          return replaced;
        };
        thisApp[routeName + '_url'] = function() {
          var urlOpts = thisApp.default_url_options.host;
          if (thisApp.default_url_options.port && parseInt(thisApp.default_url_options.port) != 80)
            urlOpts += ':' + thisApp.default_url_options.port;
          
          return urlOpts + thisApp[routeName + '_path'](arguments);
        };
      }(this));
    }
  };
  Application.prototype = {
    name: null,
    default_url_options: {},
    routes: {},
  };

  Excursion = {
    registerApplication: function(app, name) {
      if (!name)
        name = app.name;
      
      this[name] = new Application(app);
    },

    loadPool: function(pool) {
      for (app in pool) {
        this.registerApplication(pool[app]);
      }
    }
  };
}());
