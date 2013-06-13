require 'yaml'
require 'excursion/datasources/datasource'

module Excursion
  module Datasources
    class File < Datasource

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

      def initialize(path=nil)
        path ||= Excursion.configuration.datasource_file
        raise DatasourceConfigurationError, "You must configure the :file datasource with a datasource_file path" if path.nil?
        @path = ::File.expand_path(path)
      rescue DatasourceConfigurationError => e
        raise e
      rescue
        raise DatasourceConfigurationError, "Could not initialize the :file datasource. Make sure you have properly configured the datasource_file path"
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
        raise
        FileUtils.mkpath(::File.dirname(@path))
        ::File.open(@path, 'w') { |f| f.write(results.to_yaml)}
      rescue
        raise DatasourceConfigurationError, "Could not write to the excursion route pool file: #{@path}"
      end
    end
  end
end
