require 'spec_helper'

class Excursion::Specs::TestHelperOne
  include Excursion::Helpers::ApplicationHelper
end
class Excursion::Specs::TestHelperTwo
  include Excursion::Helpers::ApplicationHelper
end

describe 'Excursion' do
  before(:each) do
    Excursion::Pool.class_variable_set(:@@applications, {})
    File.unlink(Excursion::Specs::DUMMY_POOL_FILE) if File.exists?(Excursion::Specs::DUMMY_POOL_FILE)
    Excursion.configure do |config|
      config.datastore = :file
      config.datastore_file = Excursion::Specs::DUMMY_POOL_FILE
    end
  end

  after(:each) do
    Excursion::Pool.class_variable_set(:@@applications, {})
    File.unlink(Excursion::Specs::DUMMY_POOL_FILE) if File.exists?(Excursion::Specs::DUMMY_POOL_FILE)
    Excursion.configure do |config|
      config.datastore = nil
      config.datastore_file = nil
      config.memcache_server = nil
    end
  end
  
  context '::url_helpers' do
    it 'should provide access to application url helpers' do
      Excursion::Pool.register_application(Rails.application)
      expect { Excursion.url_helpers.dummy }.to_not raise_exception(NoMethodError)
    end
  end
end

describe 'Excursion::Helpers' do
  before(:each) do
    Excursion::Pool.class_variable_set(:@@applications, {})
    File.unlink(Excursion::Specs::DUMMY_POOL_FILE) if File.exists?(Excursion::Specs::DUMMY_POOL_FILE)
    Excursion.configure do |config|
      config.datastore = :file
      config.datastore_file = Excursion::Specs::DUMMY_POOL_FILE
    end
  end

  after(:each) do
    Excursion::Pool.class_variable_set(:@@applications, {})
    File.unlink(Excursion::Specs::DUMMY_POOL_FILE) if File.exists?(Excursion::Specs::DUMMY_POOL_FILE)
    Excursion.configure do |config|
      config.datastore = nil
      config.datastore_file = nil
      config.memcache_server = nil
    end
  end
  
  it 'should share instances of helper classes' do
    h1 = Excursion::Specs::TestHelperOne.new
    h2 = Excursion::Specs::TestHelperTwo.new
    Excursion::Pool.register_application(Rails.application)
    h1.dummy.should eql(h2.dummy)
    h1.dummy.should eql(Excursion::Specs::TestHelperOne.new.dummy)
  end
end
