module Excursion
  class Engine < Rails::Engine
    # automatically registers excursion as an engine and allows
    # using the javascript helpers
  end

  class Railtie < Rails::Railtie
    config.after_initialize do |app|
      if Excursion.configuration.register_app == true && !Excursion.configuration.datastore.nil? && !defined?(Rails::Generators::Base) # HACK is there a better way to attempt to check if we're running a generator?
        app.reload_routes!
        Excursion::Pool.register_application(app)
      end
    end

    rake_tasks do
      namespace :excursion do
        desc "Register this app and it's routes with the route pool"
        task :register => :environment do
          Excursion::Pool.register_application(Rails.application)
        end

        desc "Remove this app and it's routes from the route pool"
        task :remove => :environment do
          Excursion::Pool.remove_application(Rails.application)
        end
      end
    end
  end
end
