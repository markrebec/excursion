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
      config = {default_url_options: Excursion.configuration.default_url_options}
      
      @@applications[name] = Application.new(name, config, app.routes.named_routes)
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

      case Excursion.configuration.datastore.to_sym
      when :file
        raise DatastoreConfigurationError, "You must configure the :file datastore with a datastore_file path" if Excursion.configuration.datastore_file.nil?
        @@datastore ||= Excursion::Datastores::File.new(Excursion.configuration.datastore_file)
      when :memcache
        raise MemcacheConfigurationError, "You must configure the :memcache datastore with a memcache_server" if Excursion.configuration.memcache_server.nil?
        @@datastore ||= Excursion::Datastores::Memcache.new(Excursion.configuration.memcache_server)
      end
    end
  end
end
