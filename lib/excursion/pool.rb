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
      @@applications
    end

    def self.application(name)
      check_local_cache
      return @@applications[name] if @@applications.has_key?(name) && !@@applications[name].nil?
      
      app = datastore.app(name)
      @@applications[name] = app unless app.nil?
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
        if name && @@applications.has_key?(name)
          DSL.block_eval(@@applications[name], &block)
        else
          block_app = DSL.block_eval(&block)
          name = block_app.name
          @@applications[name] = block_app
        end
      end
      
      if opts[:store]
        datastore.set(name, @@applications[name].to_cache)
        datastore.set('_pool_updated', Time.now.to_i)
      end
      @@applications[name]
    end

    def self.register_hash(app_hash, opts={})
      raise ArgumentError, "you must provide at minimum a hash with a :name key" unless app_hash.is_a?(Hash) && app_hash.has_key?(:name)
      opts = {store: true}.merge(opts)
      
      app_hash = {default_url_options: Excursion.configuration.default_url_options, routes: {}, registered_at: Time.now}.merge(app_hash)
      name = app_hash[:name]

      if opts[:store]
        datastore.set(name, app_hash)
        datastore.set('_pool_updated', Time.now.to_i)
      end
      @@applications[name] = datastore.app(name)
    end

    def self.remove_application(app)
      raise ArgumentError, "app must be an instance of Rails::Application" unless app.is_a?(Rails::Application)
      
      name = app.class.name.underscore.split("/").first
      datastore.delete(name)
      @@applications.delete(name)
      datastore.set('_pool_updated', Time.now.to_i)
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

    def self.pool_updated
      datastore.get('_pool_updated').to_i || 0
    end

    def self.pool_refreshed
      @@refreshed ||= 0
    end

    def self.check_local_cache
      (@@refreshed = Time.now.to_i) && (@@applications = {}) if pool_updated > pool_refreshed
    end
  end
end
