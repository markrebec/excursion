module Excursion
  class Railtie < Rails::Railtie
    config.after_initialize do |app|
      if Excursion.configuration.register_app == true && !Excursion.configuration.datastore.nil? &&
         (Excursion.configuration.datastore.to_sym != :active_record || Excursion::RoutePool.table_exists?) # have to add this extra check because
         # otherwise trying to run the excursion:active_record generator dies when rails initializes and the datastore is already configured to :active_record
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
