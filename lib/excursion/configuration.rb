module Excursion
  class Configuration
    DEFAULT_CONFIGURATION_OPTIONS = {
      # TODO
        # exclude_pattern: to exclude certain routes from being shared
        # include_pattern: to only include certain routes
      register_app: true, # whether or not to register the app automatically on init
      default_url_options: {}, # default_url_options used when building routes for this app
      retry_limit: 3, # retry limit for datastores that user remote servers
      suppress_errors: true,
      stubbed_route_path: 'excursion/not-found',
      enable_cors: false, # enables cross-origin resource sharing for this app
      cors_whitelist: :pool, # whitelist for allowing cors for specific domains - defaults to only allow registered excursion apps
      cors_blacklist: nil, # blacklist for denying cors for specific domains
      cors_allow_methods: %w(POST PUT PATCH GET DELETE), # list of allowed cors request methods (Access-Control-Allow-Methods)
      cors_allow_headers: %w(origin content-type accept x-requested-with x-csrf-token), # list of allowed cors request headers (Access-Control-Allow-Headers)
      cors_allow_credentials: true, # allow credentials with cors requests (Access-Control-Allow-Credentials)
      cors_max_age: 1728000 # cors max age (Access-Control-Max-Age)
    }

    #attr_reader *DEFAULT_CONFIGURATION_OPTIONS.keys

    #DEFAULT_CONFIGURATION_OPTIONS.keys.each do |key|
    #  define_method "#{key.to_s}=" do |val|
    #    @changed[key] = [send(key), val]
    #    instance_variable_set "@#{key.to_s}", val
    #  end
    #end

    def method_missing(meth, *args)
      if meth.to_s.match(/\A(.*)=\Z/)
        @changed[$1] = [send($1), *args]
        instance_variable_set "@#{$1.to_s}", *args
      else
        instance_variable_get "@#{meth}"
      end
    end

    # Returns a hash of all the changed keys and values after being reconfigured
    def changed
      @changed = {}
      to_hash.each { |key,val| @changed[key] = [@saved_state[key], val] if @saved_state[key] != val }
      @changed
    end

    # Check whether a key was changed after being reconfigured
    def changed?(key)
      changed.has_key?(key)
    end

    # Pass arguments and/or a block to configure the available options
    def configure(args={}, &block)
      save_state
      configure_with_args args
      configure_with_block &block if block_given?
      self
    end

    # Accepts arguments which are used to configure available options
    def configure_with_args(args)
      args.select { |k,v| DEFAULT_CONFIGURATION_OPTIONS.keys.include?(k) }.each do |key,val|
        instance_variable_set "@#{key.to_s}", val
      end
    end

    # Accepts a block which is used to configure available options
    def configure_with_block(&block)
      self.instance_eval(&block) if block_given?
    end

    # Saves a copy of the current state, to be used later to determine what was changed
    def save_state
      @saved_state = clone.to_hash
      @changed = {}
    end

    def to_hash
      h = {}
      DEFAULT_CONFIGURATION_OPTIONS.keys.each do |key|
        h[key] = instance_variable_get "@#{key.to_s}"
      end
      h
    end
    alias_method :to_h, :to_hash

    protected

    def initialize
      DEFAULT_CONFIGURATION_OPTIONS.each do |key,val|
        instance_variable_set "@#{key.to_s}", val
      end
      save_state
      super
    end

  end
end
