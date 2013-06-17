require 'spec_helper'

describe 'Excursion::Pool::Application' do

  context '::new' do
    it 'should require a name' do
      expect { Excursion::Pool::Application.new }.to raise_exception(ArgumentError)
    end

    it 'should require a config hash' do
      expect { Excursion::Pool::Application.new 'app_name' }.to raise_exception(ArgumentError)
    end

    it 'should accept an optional route collection' do
      expect { Excursion::Pool::Application.new 'app_name', {} }.to_not raise_exception(ArgumentError)
      expect { Excursion::Pool::Application.new 'app_name', {}, {} }.to_not raise_exception(ArgumentError)
    end

    it 'should return a populated Application object' do
      mock = Excursion::Specs::Mocks::SIMPLE_APP
      mock_routes = Excursion::Specs::Mocks::NAMED_ROUTES
      
      app = Excursion::Pool::Application.new mock[:name], {default_url_options: mock[:default_url_options], registered_at: mock[:registered_at]}, mock_routes
      app.should be_an_instance_of(Excursion::Pool::Application)
      app.name.should eql(mock[:name])
      app.default_url_options.should eql(mock[:default_url_options])
      mock_routes.each do |name,path|
        app.routes.routes.keys.should include(name)
      end
    end
  end

  describe '::from_cache' do
    it 'should require a cached application hash' do
      expect { Excursion::Pool::Application.from_cache }.to raise_exception(ArgumentError)
    end

    it 'should return an Application object with the cached properties' do
      mock = Excursion::Specs::Mocks::SIMPLE_APP
      
      app = Excursion::Pool::Application.from_cache(mock)
      app.should be_an_instance_of(Excursion::Pool::Application)
      app.name.should eql(mock[:name])
      app.default_url_options.should eql(mock[:default_url_options])
      mock[:routes].each do |name,path|
        app.routes.routes.keys.should include(name)
      end
    end
  end

  describe '#to_cache' do
    subject { Excursion::Pool::Application.from_cache(Excursion::Specs::Mocks::SIMPLE_APP) }

    it 'should return a hash' do
      subject.to_cache.should be_an_instance_of(Hash)
    end

    context 'returned hash' do
      it 'should contain the app name' do
        subject.to_cache[:name].should eql(subject.name)
      end
      
      it 'should contain the default_url_options' do
        subject.to_cache[:default_url_options].should eql(subject.default_url_options)
      end

      it 'should contain a hash of the routes' do
        subject.to_cache[:routes].should be_an_instance_of(Hash)
        subject.to_cache[:routes].each do |name,path|
          subject.routes.routes.keys.should include(name)
        end
      end

      it 'should contain the registered_at property' do
        subject.to_cache[:registered_at].should eql(subject.instance_variable_get(:@registered_at))
      end
    end
  end

  describe '#from_cache' do
    subject { Excursion::Pool::Application.new 'test_app', {} }

    it 'should require a cached application object' do
      expect { subject.from_cache }.to raise_exception(ArgumentError)
    end

    it 'should populate the object with the cached values' do
      mock = Excursion::Specs::Mocks::SIMPLE_APP
      subject.from_cache(mock)
      subject.default_url_options.should eql(mock[:default_url_options])
      subject.instance_variable_get(:@registered_at).to_i.should eql(mock[:registered_at].to_i)
      subject.routes.each do |name,path|
        mock[:routes].keys.should include(name)
      end
    end
  end

  describe '#route' do
    subject { Excursion::Pool::Application.from_cache(Excursion::Specs::Mocks::SIMPLE_APP) }
    
    it 'should require a name' do
      expect { subject.route }.to raise_exception(ArgumentError)
    end

    context 'when the route exists' do
      it 'should return the route object' do
        if Excursion.rails3?
          subject.route(:example).should be_an_instance_of(Journey::Route)
        elsif Excursion.rails4?
          subject.route(:example).should be_an_instance_of(ActionDispatch::Journey::Route)
        end
      end
    end

    context 'when the route does not exist' do
      it 'should return nil' do
        subject.route(:non_existent_route).should be_nil
      end
    end
  end

  describe '#routes' do
    subject { Excursion::Pool::Application.from_cache(Excursion::Specs::Mocks::SIMPLE_APP) }

    it 'should return a NamedRouteCollection' do
      subject.routes.should be_an_instance_of(ActionDispatch::Routing::RouteSet::NamedRouteCollection)
    end
  end

  describe '#routes=' do
    subject { Excursion::Pool::Application.new 'test_app', {} }
    
    it 'should accept a Hash of named routes' do
      expect { subject.routes = {} }.to_not raise_exception(ArgumentError)
    end

    it 'should accept a NamedRouteCollection' do
      expect { subject.routes = ActionDispatch::Routing::RouteSet::NamedRouteCollection.new }.to_not raise_exception(ArgumentError)
    end

    it 'should only accept a Hash or NamedRouteCollection' do
      expect { subject.routes = 'test string' }.to raise_exception(ArgumentError)
      expect { subject.routes = 123 }.to raise_exception(ArgumentError)
      expect { subject.routes = :test_symbol }.to raise_exception(ArgumentError)
      expect { subject.routes = [] }.to raise_exception(ArgumentError)
      expect { subject.routes = Object }.to raise_exception(ArgumentError)
      expect { subject.routes = Object.new }.to raise_exception(ArgumentError)
    end
    
    context 'when passing a Hash' do
      it 'should override the application routes with the ones provided' do
        subject.routes = Hash[Excursion::Specs::Mocks::NAMED_ROUTES.collect {|k,v| [k,v] }]
        Excursion::Specs::Mocks::NAMED_ROUTES.each do |name,path|
          subject.routes.routes.keys.should include(name)
        end
      end
    end

    context 'when passing a NamedRouteCollection' do
      it 'should override the application routes with the ones provided' do
        subject.routes = Excursion::Specs::Mocks::NAMED_ROUTES
        Excursion::Specs::Mocks::NAMED_ROUTES.each do |name,path|
          subject.routes.routes.keys.should include(name)
        end
      end
    end
  end

  describe '#set_routes' do
    subject { Excursion::Pool::Application.new 'test_app', {} }
    
    context 'routes' do
      it 'should be required' do
        expect { subject.set_routes }.to raise_exception(ArgumentError)
      end
      
      it 'should accept a Hash of named routes' do
        expect { subject.set_routes({}) }.to_not raise_exception(ArgumentError)
      end

      it 'should accept a NamedRouteCollection' do
        expect { subject.set_routes ActionDispatch::Routing::RouteSet::NamedRouteCollection.new }.to_not raise_exception(ArgumentError)
      end

      it 'should only accept a Hash or NamedRouteCollection' do
        expect { subject.set_routes 'test string' }.to raise_exception(ArgumentError)
        expect { subject.set_routes 123 }.to raise_exception(ArgumentError)
        expect { subject.set_routes :test_symbol }.to raise_exception(ArgumentError)
        expect { subject.set_routes [] }.to raise_exception(ArgumentError)
        expect { subject.set_routes Object }.to raise_exception(ArgumentError)
        expect { subject.set_routes Object.new }.to raise_exception(ArgumentError)
      end
    end
    
    context 'when passing a Hash' do
      it 'should override the application routes with the ones provided' do
        subject.set_routes Hash[Excursion::Specs::Mocks::NAMED_ROUTES]
        Excursion::Specs::Mocks::NAMED_ROUTES.each do |name,path|
          subject.routes.routes.keys.should include(name)
        end
      end
    end

    context 'when passing a NamedRouteCollection' do
      it 'should override the application routes with the ones provided' do
        subject.set_routes Excursion::Specs::Mocks::NAMED_ROUTE_COLLECTION
        Excursion::Specs::Mocks::NAMED_ROUTES.each do |name,path|
          subject.routes.routes.keys.should include(name)
        end
      end
    end
  end

end
