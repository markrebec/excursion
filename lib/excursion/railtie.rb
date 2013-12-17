module Excursion
  class Railtie < Rails::Railtie
    config.after_initialize do |app|
      # Do not register on init when running a generator (is there a better way to detect this? Maybe $0 == 'rails' && ARGV.include?('generate') or 'g')
      # Do not register on init when running a rake task
      if Excursion.configuration.register_app == true && !Excursion.configuration.datastore.nil? && !defined?(Rails::Generators::Base) && File.basename($0) != "rake"
        app.reload_routes!
        Excursion::Pool.register_application(app)
      end

      ActionController::Base.send :include, Excursion::Builders::ApplicationBuilder
      ActionController::Base.send :helper, Excursion::Builders::ApplicationBuilder
      ActionController::Base.send :include, Excursion::CORS if Excursion.configuration.enable_cors
    end

    rake_tasks do
      namespace :excursion do
        desc "Register this app and it's routes with the route pool"
        task :register => :environment do
          app = Excursion::Pool.register_application(Rails.application)
          puts "Registered application #{app.name} in the #{Rails.env} route pool."
        end

        desc "Remove this app and it's routes from the route pool"
        task :remove => :environment do
          Excursion::Pool.remove_application(Rails.application)
          puts "Rmoved application #{app.name} from the #{Rails.env} route pool."
        end
      end
    end
  end
end
