require 'excursion/pool/application'
require 'excursion/pool/dsl'
require 'excursion/exceptions/pool'
require 'excursion/exceptions/datastores'

module Excursion
  module Pool
    @@applications = {}

    def self.all_applications
      datastore.all_apps.each do |app|
        @@applications[app.name] = app
      end
    end

    def self.application(name)
      return @@applications[name] if @@applications.has_key?(name) && !@@applications[name].nil?
      
      @@applications[name] = datastore.app(name)
    end

    def self.register_application(app=nil, opts={}, &block)
      raise ArgumentError, "app must be an instance of Rails::Application" unless app.is_a?(Rails::Application) || block_given?
      opts = {store: true}.merge(opts)
      
      if app.is_a?(Rails::Application)
        name = app.class.name.underscore.split("/").first
        config = {default_url_options: Excursion.configuration.default_url_options}
        routes = app.routes.named_routes
        @@applications[name] = Application.new(name, config, routes)
      end
      
      if block_given?
        if @@applications.has_key?(name)
          DSL.block_eval(@@applications[name], &block)
        else
          block_app = DSL.block_eval(&block)
          name = block_app.name
          @@applications[name] = block_app
        end
      end
      
      datastore.set(name, @@applications[name].to_cache) if opts[:store]
      @@applications[name]
    end

    def self.register_hash(app_hash)
      raise ArgumentError, "you must provide at minimum a hash with a :name key" unless app_hash.is_a?(Hash) && app_hash.has_key?(:name)
      
      app_hash = {default_url_options: Excursion.configuration.default_url_options, routes: {}, registered_at: Time.now}.merge(app_hash)
      name = app_hash[:name]

      datastore.set(name, app_hash)
      @@applications[name] = datastore.app(name)
    end

    def self.remove_application(app)
      raise ArgumentError, "app must be an instance of Rails::Application" unless app.is_a?(Rails::Application)
      
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
      when :active_record
        raise TableDoesNotExist, "To use the :active_record datastore you must first run `rails generate excursion:active_record` followed by `rake db:migrate` to create the storage table" unless Excursion::RoutePool.table_exists?
        @@datastore ||= Excursion::Datastores::ActiveRecord.new
      when :active_record_with_memcache
        raise MemcacheConfigurationError, "You must configure the :active_record_with_memcache datastore with a memcache_server" if Excursion.configuration.memcache_server.nil?
        raise TableDoesNotExist, "To use the :active_record_with_memcache datastore you must first run `rails generate excursion:active_record` followed by `rake db:migrate` to create the storage table" unless Excursion::RoutePool.table_exists?
        @@datastore ||= Excursion::Datastores::ActiveRecord.new(Excursion.configuration.memcache_server)
      when :test
        @@datastore ||= Excursion::Datastores::Test.new
      end
    end
  end
end
