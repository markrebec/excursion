require 'excursion/builders/application_builder'
require 'excursion/builders/url_builder'
require 'excursion/builders/stub_builder'

module Excursion
  module Builders
    def self.builders
      @builders ||= {}
    end

    def self.builder(name)
      builders[name]
    end

    # Builders register themselves here when they're created so they can be shared
    # between different instances (like the StaticBuilder below and ActionController)
    def self.register_builder(h)
      @builders ||= {}
      @builders[h.application.name] = h
      h
    end

    class StaticBuilder
      include ApplicationBuilder
    end
  end

  # Provides quick global access to url builders with using the StaticBuilder
  def self.url_helpers
    @url_helpers ||= Builders::StaticBuilder.new
  end
end
