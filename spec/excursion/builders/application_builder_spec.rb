require 'spec_helper'

describe 'Excursion::Builders::ApplicationBuilder' do
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

  describe '#excursion' do
    it 'should require an application name' do
      expect { Excursion.url_helpers.excursion }.to raise_exception(ArgumentError)
    end

    context 'when the requested application is in the pool' do
      it 'should return an application UrlBuilder for the app' do
        Excursion.url_helpers.excursion('dummy').should be_an_instance_of(Excursion::Builders::UrlBuilder)
        Excursion.url_helpers.excursion('dummy').application.should eql(Excursion::Pool.application('dummy'))
      end
    end
    
    context 'when the requested application is not in the pool' do
      it 'should raise a NotInPool error' do
        expect { Excursion.url_helpers.excursion('not_in_pool') }.to raise_exception(Excursion::NotInPool)
      end
    end
  end

  it 'should allow referencing application builder methods directly by name' do
    expect { Excursion.url_helpers.dummy }.to_not raise_exception#(NoMethodError)
    Excursion.url_helpers.dummy.should eql(Excursion.url_helpers.excursion('dummy'))
  end

end
