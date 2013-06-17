require 'yaml'
require 'excursion/datastores/datastore'

module Excursion
  module Datastores
    class File < Datastore

      def read(key)
        read_file[key.to_s]
      end
      alias_method :get, :read
      
      def write(key, value)
        current = read_file
        current[key.to_s] = value
        write_file(current)
        current[key.to_s]
      end
      alias_method :set, :write

      def delete(key)
        current = read_file
        deleted = current.delete(key.to_s)
        write_file(current)
        deleted
      end
      alias_method :unset, :delete

      protected

      def initialize(path)
        raise DatastoreConfigurationError if path.nil? || path.to_s.empty?
        @path = ::File.expand_path(path)
      rescue
        raise DatastoreConfigurationError, "Could not initialize the :file datastore with path: '#{path}'"
      end

      def exists?
        ::File.exists(@path)
      end

      def read_file
        YAML.load_file(@path) || {}
      rescue
        {}
      end

      def write_file(results)
        FileUtils.mkpath(::File.dirname(@path))
        ::File.open(@path, 'w') { |f| f.write(results.to_yaml)}
      rescue
        raise DatastoreConfigurationError, "Could not write to the excursion route pool file: #{@path}"
      end
    end
  end
end
