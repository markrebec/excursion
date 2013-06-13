module Excursion
  class Railtie < Rails::Railtie
    config.after_initialize do |app|
      unless Excursion.configuration.register_app == false
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
