module Excursion
  class AssetMiddleware
    def initialize(app)
      @app = app
    end
   
    def call(env)
      request = Rack::Request.new(env)
      response = @app.call(env)
      if request.path =~ /^\/assets\/excursion\//
        response[1]["Last-Modified"] = Time.at(Excursion::Pool.pool_updated).strftime('%a, %d %b %Y %H:%M:%S %Z')
      end
      response
    end
  end
end
