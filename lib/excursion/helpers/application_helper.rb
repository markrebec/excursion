module Excursion
  module Helpers
    module ApplicationHelper
      
      # Returns an Excursion::Helpers::ApplicationHelper if the app exists in the route pool.
      #
      # Raises an exception if the requested app is not in the route pool.
      def excursion(app_name)
        raise NotInPool, "Application is not registered in the excursion route pool: '#{app_name}'" unless app_exists?(app_name)
        
        return Helpers.helper(app_name) unless Helpers.helper(app_name).nil?
        Helpers.register_helper(UrlHelper.new(app_name))
      end

      def method_missing(meth, *args)
        excursion(meth.to_s)
      rescue
        super
      end

      def respond_to_missing?(meth, include_private=false)
        app_exists?(meth.to_s) || super
      end

      protected

      def app_exists?(app_name)
        !excursion_app(app_name).nil?
      end

      def excursion_app(app_name)
        Pool.application(app_name)
      end
    end
  end
end

ActionController::Base.send :include, Excursion::Helpers::ApplicationHelper
ActionController::Base.send :helper, Excursion::Helpers::ApplicationHelper
