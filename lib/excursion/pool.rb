require 'excursion/pool/application'

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

    def self.datasource
      raise if Excursion.configuration.datasource.nil?
      require "excursion/datasources/#{Excursion.configuration.datasource.to_s}"
      @@datasource ||= "Excursion::Datasources::#{Excursion.configuration.datasource.to_s.camelize}".constantize.new
    rescue
      raise "Could not initialize your datasource. Make sure you have properly configured it"
    end
  end
end
