require File.expand_path("../dummy/config/environment", __FILE__)
require 'rspec/core'
#require 'rspec/rails'
#require 'rspec/autorun'

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  #config.before(:suite) do
  #end

  #config.before(:each) do
  #end

  #config.around(:each) do |example|
    #ActiveRecord::Base.transaction do
    #  example.run
    #  raise ActiveRecord::Rollback
    #end
  #end
end
