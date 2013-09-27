require 'spec_helper'

describe 'Excursion::Pool' do
  DUMMY_HASH = {name: 'dummy', default_url_options: {host: 'dummy.local', port: 3000}, routes: {root: '/', other_route: '/other/route'}}

  describe '::datastore' do
    cleaner = Proc.new do
      Excursion::Pool.class_variable_set(:@@datastore, nil)
      Excursion.configure do |config|
        datastore = nil
        datastore_file = nil
        memcache_server = nil
      end
    end
    before :each, &cleaner
    after :each, &cleaner

    it 'should require a configured datastore' do
      expect { Excursion::Pool.datastore }.to raise_exception(Excursion::NoDatastoreError)
    end

    it 'should support the :file datastore' do
      Excursion.configuration.datastore = :file
      Excursion.configuration.datastore_file = 'tmp/.rout_pool'
      expect { Excursion::Pool.datastore }.to_not raise_exception#(Excursion::NoDatastoreError)
    end

    it 'should support the :memcache datastore' do
      Excursion.configuration.datastore = :memcache
      Excursion.configuration.memcache_server = 'localhost:11211'
      expect { Excursion::Pool.datastore }.to_not raise_exception#(Excursion::NoDatastoreError)
    end

    context 'when using the :file datastore' do
      it 'should require the datastore_file option be configured' do
        Excursion.configuration.datastore = :file
        Excursion.configuration.datastore_file = nil
        expect { Excursion::Pool.datastore }.to raise_exception(Excursion::DatastoreConfigurationError)
      end

      it 'should return an instance of Excursion::Datastores::File' do
        Excursion.configuration.datastore = :file
        Excursion.configuration.datastore_file = Excursion::Specs::DUMMY_POOL_FILE
        Excursion::Pool.datastore.should be_an_instance_of(Excursion::Datastores::File)
      end
    end

    context 'when using the :memcache datastore' do
      it 'should require the memcache_server option be configured' do
        Excursion.configuration.datastore = :memcache
        Excursion.configuration.memcache_server = nil
        expect { Excursion::Pool.datastore }.to raise_exception(Excursion::MemcacheConfigurationError)
      end
      
      it 'should return an instance of Excursion::Datastores::Memcache' do
        Excursion.configuration.datastore = :memcache
        Excursion.configuration.memcache_server = Excursion::Specs::DUMMY_MEMCACHE_SERVER
        Excursion::Pool.datastore.should be_an_instance_of(Excursion::Datastores::Memcache)
      end
    end
  end
  
  describe '::register_application' do
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

    it 'should require a rails application and/or a block' do
      expect { Excursion::Pool.register_application }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.register_application 'string arg' }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.register_application 123 }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.register_application :symbol_arg }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.register_application Object }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.register_application Object.new }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.register_application Rails.application }.to_not raise_exception
      expect { Excursion::Pool.register_application do; end }.to_not raise_exception
      expect { Excursion::Pool.register_application(Rails.application) do; end }.to_not raise_exception
    end

    it 'should add the application to the local hash pool' do
      Excursion::Pool.class_variable_get(:@@applications).should_not have_key('dummy')
      Excursion::Pool.register_application(Rails.application) # Use the dummy app class
      Excursion::Pool.class_variable_get(:@@applications).should have_key('dummy')
    end

    it 'should set the application in the datastore pool' do
      Excursion::Pool.datastore.get('dummy').should be_nil
      Excursion::Pool.register_application(Rails.application) # Use the dummy app class
      Excursion::Pool.datastore.get('dummy').should_not be_nil
    end
  end

  describe '::register_hash' do
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

    it 'should require a hash with a :name key' do
      expect { Excursion::Pool.register_hash }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.register_hash {} }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.register_hash 'string arg' }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.register_hash 123 }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.register_hash :symbol_arg }.to raise_exception(ArgumentError)
    end

    it 'should add the application to the local hash pool' do
      Excursion::Pool.class_variable_get(:@@applications).should_not have_key('dummy')
      Excursion::Pool.register_hash(DUMMY_HASH)
      Excursion::Pool.class_variable_get(:@@applications).should have_key('dummy')
    end

    it 'should set the application in the datastore pool' do
      Excursion::Pool.datastore.get('dummy').should be_nil
      Excursion::Pool.register_hash(DUMMY_HASH)
      Excursion::Pool.datastore.get('dummy').should_not be_nil
    end
  end

  describe '::remove_application' do
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
    
    it 'should require a rails application as the only argument' do
      expect { Excursion::Pool.remove_application }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.remove_application 'string arg' }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.remove_application 123 }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.remove_application :symbol_arg }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.remove_application Object }.to raise_exception(ArgumentError)
      expect { Excursion::Pool.remove_application Object.new }.to raise_exception(ArgumentError)
    end

    it 'should remove the application from the local hash pool' do
      Excursion::Pool.class_variable_get(:@@applications).should_not have_key('dummy')
      Excursion::Pool.register_application(Rails.application) # Use the dummy app class
      Excursion::Pool.class_variable_get(:@@applications).should have_key('dummy')
      Excursion::Pool.remove_application(Rails.application)
      Excursion::Pool.class_variable_get(:@@applications).should_not have_key('dummy')
    end

    it 'should remove the application from the datastore pool' do
      Excursion::Pool.datastore.get('dummy').should be_nil
      Excursion::Pool.register_application(Rails.application) # Use the dummy app class
      Excursion::Pool.datastore.get('dummy').should_not be_nil
      Excursion::Pool.remove_application(Rails.application)
      Excursion::Pool.datastore.get('dummy').should be_nil
    end
  end

  describe '::application' do
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
    
    it 'should require an application name string' do
      expect { Excursion::Pool.application }.to raise_exception(ArgumentError)
    end
    
    context 'when the requested app exists' do
      context 'in the local hash pool' do
        before(:each) do
          Excursion::Pool.register_application(Rails.application)
        end

        it 'should return the Application object' do
          Excursion::Pool.class_variable_get(:@@applications).should have_key('dummy')
          Excursion::Pool.application('dummy').should be_an_instance_of(Excursion::Pool::Application)
          Excursion::Pool.application('dummy').should eql(Excursion::Pool.class_variable_get(:@@applications)['dummy'])
        end
      end

      context 'in the datastore pool' do
        before(:each) do
          Excursion::Pool.register_application(Rails.application)
          Excursion::Pool.class_variable_set(:@@applications, {})
        end

        it 'should return the Application object' do
          Excursion::Pool.class_variable_get(:@@applications).should_not have_key('dummy')
          Excursion::Pool.application('dummy').should be_an_instance_of(Excursion::Pool::Application)
          Excursion::Pool.application('dummy').should eql(Excursion::Pool.class_variable_get(:@@applications)['dummy'])
        end
      end
    end

    context 'when the requested app does not exist' do
      it 'should return nil' do
        Excursion::Pool.application('dummy').should be_nil
      end
    end
  end
end
