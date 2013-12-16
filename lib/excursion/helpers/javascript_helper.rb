module Excursion
  module Helpers
    module JavascriptHelper
      def render_excursion_javascript_helpers
        content_tag :script, raw("Excursion.loadPool('#{raw Base64.encode64(Excursion::Pool.all_applications.values.map(&:to_cache).to_json.to_s).gsub("\n","")}');"), type: "text/javascript"
      end

    end
  end
end

ActionController::Base.send :helper, Excursion::Helpers::JavascriptHelper
