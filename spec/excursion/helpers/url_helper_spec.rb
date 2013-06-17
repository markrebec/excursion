require 'spec_helper'

describe 'Excursion::Helpers::UrlHelper' do
  before(:all) do
    Excursion::Pool.class_variable_set(:@@applications, {})
    File.unlink(Excursion::Specs::DUMMY_POOL_FILE) if File.exists?(Excursion::Specs::DUMMY_POOL_FILE)
    Excursion.configure do |config|
      config.datastore = :file
      config.datastore_file = Excursion::Specs::DUMMY_POOL_FILE
    end
    Excursion::Pool.register_application(Rails.application)
  end

  after(:all) do
    Excursion::Pool.class_variable_set(:@@applications, {})
    File.unlink(Excursion::Specs::DUMMY_POOL_FILE) if File.exists?(Excursion::Specs::DUMMY_POOL_FILE)
    Excursion.configure do |config|
      config.datastore = nil
      config.datastore_file = nil
      config.memcache_server = nil
    end
  end

  describe '#routes' do
    it 'should return the application NamedRouteCollection object' do
      Excursion.url_helpers.dummy.routes.should be_an_instance_of(ActionDispatch::Routing::RouteSet::NamedRouteCollection)
    end
  end

  it 'should provide url helper methods for the application named routes' do
    expect { Excursion.url_helpers.dummy.root_url }.to_not raise_exception(NoMethodError)
    expect { Excursion.url_helpers.dummy.root_path }.to_not raise_exception(NoMethodError)
    expect { Excursion.url_helpers.dummy.test_url }.to_not raise_exception(NoMethodError)
    expect { Excursion.url_helpers.dummy.test_path }.to_not raise_exception(NoMethodError)
  end

  context 'url helper methods' do
    before(:all) do
      Excursion.configuration.default_url_options = {host: 'test.example.com', port: 3000}
      Excursion::Helpers.instance_variable_get(:@helpers).delete('dummy')
      Excursion::Pool.remove_application(Rails.application)
      Excursion::Pool.register_application(Rails.application)
    end

    after(:all) do
      Excursion.configuration.default_url_options = {}
    end

    it 'should return a string representation of the route url' do
      Excursion.url_helpers.dummy.root_url.should eql('http://test.example.com:3000/')
      Excursion.url_helpers.dummy.test_url.should eql('http://test.example.com:3000/test')
      Excursion.url_helpers.dummy.test_with_replace_url('abc').should eql('http://test.example.com:3000/test/with/abc')
    end
  end
end
