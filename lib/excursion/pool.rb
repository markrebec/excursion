require 'excursion/pool/application'
require 'excursion/exceptions/pool'
require 'excursion/exceptions/datastores'

module Excursion
  module Pool
    @@applications = {}

    def self.application(name)
      return @@applications[name] if @@applications.has_key?(name)
      
      app_yaml = datastore.get(name)
      @@applications[name] = Application.from_cache(app_yaml) unless app_yaml.nil?
    end

    def self.register_application(app)
      name = app.class.name.underscore.split("/").first
      config = {name: name, default_url_options: Excursion.configuration.default_url_options}
      
      @@applications[name] = Application.new(config, app.routes.named_routes)
      datastore.set(name, @@applications[name].to_cache)
    end

    def self.remove_application(app)
      name = app.class.name.underscore.split("/").first
      datastore.delete(name)
      @@applications.delete(name)
    end

    def self.datastore
      raise NoDatastoreError, "You must configure excursion with a datastore." if Excursion.configuration.datastore.nil?
      require "excursion/datastores/#{Excursion.configuration.datastore.to_s}"
      @@datastore ||= "Excursion::Datastores::#{Excursion.configuration.datastore.to_s.camelize}".constantize.new
    #rescue NoDatastoreError => e
      #raise e
    rescue StandardError => e
      raise e
      #raise InvalidDatastoreError, "Could not initialize your datastore. Make sure you have properly configured it"
    end
  end
end
