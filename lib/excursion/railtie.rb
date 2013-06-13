module Excursion
  class Railtie < Rails::Railtie
    config.after_initialize do |app|
      app.reload_routes!
      Excursion::Pool.register_application(app)
    end
  end
end
