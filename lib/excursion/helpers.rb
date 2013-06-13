require 'excursion/helpers/url_helper'
require 'excursion/helpers/application_helper'

module Excursion
  module Helpers
    def self.helpers
      @helpers ||= {}
    end

    def self.helper(name)
      helpers[name]
    end

    # Helpers register themselves here when they're created so they can be shared
    # between different instances (like the StaticHelper below and ActionController)
    def self.register_helper(h)
      @helpers ||= {}
      @helpers[h.application.name] = h
      h
    end
  end

  class StaticHelper
    include Helpers::ApplicationHelper
  end

  # Provides quick global access to url helpers with using the StaticHelper
  def self.url_helpers
    @url_helpers ||= StaticHelper.new
  end
end
