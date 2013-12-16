/*
 * This Base64 object was extracted from the jquery-base64 plugin, as it was the cleanest and
 * simplest implementation I could find. I have avoided jquery as a dependency for excursion
 * thus far, and would like to continue doing so where possible, so the jquery wrapper was
 * removed and it has been included here.
 *
 * Full credit for this base64 functionality goes to Carlo Zottman (https://github.com/carlo)
 * and his jquery plugin jquery-base64 (https://github.com/carlo/jquery-base64)
 */
Base64 = (function() {
  
  var _PADCHAR = "=",
    _ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
    _VERSION = "1.0";


  function _getbyte64( s, i ) {
    // This is oddly fast, except on Chrome/V8.
    // Minimal or no improvement in performance by using a
    // object with properties mapping chars to value (eg. 'A': 0)

    var idx = _ALPHA.indexOf( s.charAt( i ) );

    if ( idx === -1 ) {
      throw "Cannot decode base64";
    }

    return idx;
  }
  
  
  function _decode( s ) {
    var pads = 0,
      i,
      b10,
      imax = s.length,
      x = [];

    s = String( s );
    
    if ( imax === 0 ) {
      return s;
    }

    if ( imax % 4 !== 0 ) {
      throw "Cannot decode base64";
    }

    if ( s.charAt( imax - 1 ) === _PADCHAR ) {
      pads = 1;

      if ( s.charAt( imax - 2 ) === _PADCHAR ) {
        pads = 2;
      }

      // either way, we want to ignore this last block
      imax -= 4;
    }

    for ( i = 0; i < imax; i += 4 ) {
      b10 = ( _getbyte64( s, i ) << 18 ) | ( _getbyte64( s, i + 1 ) << 12 ) | ( _getbyte64( s, i + 2 ) << 6 ) | _getbyte64( s, i + 3 );
      x.push( String.fromCharCode( b10 >> 16, ( b10 >> 8 ) & 0xff, b10 & 0xff ) );
    }

    switch ( pads ) {
      case 1:
        b10 = ( _getbyte64( s, i ) << 18 ) | ( _getbyte64( s, i + 1 ) << 12 ) | ( _getbyte64( s, i + 2 ) << 6 );
        x.push( String.fromCharCode( b10 >> 16, ( b10 >> 8 ) & 0xff ) );
        break;

      case 2:
        b10 = ( _getbyte64( s, i ) << 18) | ( _getbyte64( s, i + 1 ) << 12 );
        x.push( String.fromCharCode( b10 >> 16 ) );
        break;
    }

    return x.join( "" );
  }
  
  
  function _getbyte( s, i ) {
    var x = s.charCodeAt( i );

    if ( x > 255 ) {
      throw "INVALID_CHARACTER_ERR: DOM Exception 5";
    }
    
    return x;
  }


  function _encode( s ) {
    if ( arguments.length !== 1 ) {
      throw "SyntaxError: exactly one argument required";
    }

    s = String( s );

    var i,
      b10,
      x = [],
      imax = s.length - s.length % 3;

    if ( s.length === 0 ) {
      return s;
    }

    for ( i = 0; i < imax; i += 3 ) {
      b10 = ( _getbyte( s, i ) << 16 ) | ( _getbyte( s, i + 1 ) << 8 ) | _getbyte( s, i + 2 );
      x.push( _ALPHA.charAt( b10 >> 18 ) );
      x.push( _ALPHA.charAt( ( b10 >> 12 ) & 0x3F ) );
      x.push( _ALPHA.charAt( ( b10 >> 6 ) & 0x3f ) );
      x.push( _ALPHA.charAt( b10 & 0x3f ) );
    }

    switch ( s.length - imax ) {
      case 1:
        b10 = _getbyte( s, i ) << 16;
        x.push( _ALPHA.charAt( b10 >> 18 ) + _ALPHA.charAt( ( b10 >> 12 ) & 0x3F ) + _PADCHAR + _PADCHAR );
        break;

      case 2:
        b10 = ( _getbyte( s, i ) << 16 ) | ( _getbyte( s, i + 1 ) << 8 );
        x.push( _ALPHA.charAt( b10 >> 18 ) + _ALPHA.charAt( ( b10 >> 12 ) & 0x3F ) + _ALPHA.charAt( ( b10 >> 6 ) & 0x3f ) + _PADCHAR );
        break;
    }

    return x.join( "" );
  }


  return {
    decode: _decode,
    encode: _encode,
    VERSION: _VERSION
  };
      
}());

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
          var urlOpts = window.location.protocol + '//' + thisApp.default_url_options.host;
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
      if (typeof pool == "string") {
        try {
          pool = eval(pool);
        } catch(err) {
          pool = eval(Base64.decode(pool));
        }
      }

      for (app in pool) {
        this.registerApplication(pool[app]);
      }
    }
  };
}());

