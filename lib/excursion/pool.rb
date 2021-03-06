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
      return @@applications[name.to_s] if @@applications.has_key?(name.to_s) && !@@applications[name.to_s].nil?
      
      app = datastore.app(name)
      @@applications[name.to_s] = app unless app.nil?
    end

    def self.app_hash_defaults
      {default_url_options: Excursion.configuration.default_url_options, routes: {}, registered_at: Time.now}
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
      
      app_hash = app_hash_defaults.merge(app_hash)
      name = app_hash[:name]

      if opts[:store]
        datastore.set(name, app_hash)
        datastore.set('_pool_updated', Time.now.to_i)
      end
      @@applications[name.to_s] = datastore.app(name)
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

      send "#{Excursion.configuration.datastore.to_sym}_datastore"
    end

    def self.datastore_class(type)
      "Excursion::Datastores::#{type.to_s.capitalize}".constantize
    end

    def self.simple_datastore(type, config_opt)
      raise DatastoreConfigurationError, "You must configure the :#{type.to_s} datastore with a #{config_opt.to_s}" if Excursion.configuration.send(config_opt.to_sym).nil?
      @@datastore ||= datastore_class(type).new(Excursion.configuration.send(config_opt.to_sym))
    end

    def self.file_datastore
      simple_datastore(:file, :datastore_file)
    end

    def self.memcache_datastore
      simple_datastore(:memcache, :memcache_server)
    end

    def self.active_record_datastore
      raise TableDoesNotExist, "To use the :active_record datastore you must first run `rails generate excursion:active_record` followed by `rake db:migrate` to create the storage table" unless Excursion::RoutePool.table_exists?
      @@datastore ||= Excursion::Datastores::ActiveRecord.new
    end

    def self.active_record_with_memcache_datastore
      raise MemcacheConfigurationError, "You must configure the :active_record_with_memcache datastore with a memcache_server" if Excursion.configuration.memcache_server.nil?
      raise TableDoesNotExist, "To use the :active_record_with_memcache datastore you must first run `rails generate excursion:active_record` followed by `rake db:migrate` to create the storage table" unless Excursion::RoutePool.table_exists?
      @@datastore ||= Excursion::Datastores::ActiveRecord.new(Excursion.configuration.memcache_server)
    end

    def self.test_datastore
        @@datastore ||= Excursion::Datastores::Test.new
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

    def self.set_secret_key_base
      datastore.set('_secret_key_base', Digest::MD5.hexdigest(SecureRandom.base64(32)))
    end

    def self.secret_key_base
      key = datastore.get('_secret_key_base') || set_secret_key_base
    end
  end
end
