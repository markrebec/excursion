module Excursion
  module Helpers
    module Helper
      
      def method_missing(meth, *args)
        if !(app = Pool.application(meth.to_s)).nil?
          @application_helpers ||= {}
          @application_helpers[app.name] ||= ApplicationHelper.new(app)
        else
          begin
            super
          rescue NoMethodError => e
            raise "Excursion URL helper method does not exist: #{meth}"
          end
        end
      end
    end
  end
end

ActionController::Base.send :include, Excursion::Helpers::Helper
ActionController::Base.send :helper, Excursion::Helpers::Helper
