require 'excursion/pool/application'
require 'excursion/exceptions/pool'
require 'excursion/exceptions/datasources'

module Excursion
  module Pool
    @@applications = {}

    def self.application(name)
      return @@applications[name] if @@applications.has_key?(name)
      
      app_yaml = datasource.get(name)
      @@applications[name] = Application.from_cache(app_yaml) unless app_yaml.nil?
    end

    def self.register_application(app)
      name = app.class.name.underscore.split("/").first
      config = {name: name, default_url_options: Excursion.configuration.default_url_options}
      
      @@applications[name] = Application.new(config, app.routes.named_routes)
      datasource.set(name, @@applications[name].to_cache)
    end

    def self.remove_application(app)
      name = app.class.name.underscore.split("/").first
      datasource.delete(name)
      @@applications.delete(name)
    end

    def self.datasource
      raise NoDatasourceError, "You must configure excursion with a datasource." if Excursion.configuration.datasource.nil?
      require "excursion/datasources/#{Excursion.configuration.datasource.to_s}"
      @@datasource ||= "Excursion::Datasources::#{Excursion.configuration.datasource.to_s.camelize}".constantize.new
    #rescue NoDatasourceError => e
      #raise e
    rescue StandardError => e
      raise e
      #raise InvalidDatasourceError, "Could not initialize your datasource. Make sure you have properly configured it"
    end
  end
end
