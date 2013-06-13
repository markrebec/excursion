module Excursion
  module Helpers
    module Helper
      
      def method_missing(meth, *args)
        if !(app = Pool.application(meth.to_s)).nil?
          @application_helpers ||= {}
          @application_helpers[app.name] ||= ApplicationHelper.new(app)
        else
          super
        end
      end
    end

    class TestHelper
      include Helper
    end
  end
end
