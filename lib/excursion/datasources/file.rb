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
        path ||= Rails.root.join("tmp", "excursion_pool")
        @path = ::File.expand_path(path)
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
        ::File.open(@path, 'w') { |f| f.write(results.to_yaml)}
      end
    end
  end
end
