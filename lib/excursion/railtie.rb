module Excursion
  class Railtie < Rails::Railtie
    config.after_initialize do |app|
      app.reload_routes!
      Excursion::Pool.register_application(app)
    end

    rake_tasks do
      namespace :excursion do
        desc "Register this app and it's routes with the route pool"
        task :register => :environment do
          Excursion::Pool.register_application(Rails.application)
        end
      end
    end
  end
end
