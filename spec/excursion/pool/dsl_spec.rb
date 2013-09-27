require 'spec_helper'

describe 'Excursion::Pool::DSL' do

  context 'when an application is provided' do
    let(:dummy_app) { Excursion::Pool::Application.new('dummy', {}) }

    it 'should use the provided application' do
      expect(Excursion::Pool::DSL.block_eval(dummy_app)).to eql(dummy_app)
    end

    it 'should allow overriding the name of the application' do
      modified = Excursion::Pool::DSL.block_eval(dummy_app) do
        name 'modified'
      end
      expect(modified.name).to eql('modified')
      expect(modified).to eql(dummy_app)
    end

    it 'should allow overriding the default_url_options for the application' do
      url_opts = {host: 'dummy.local', port: 1234}
      modified = Excursion::Pool::DSL.block_eval(dummy_app) do
        default_url_options url_opts
      end
      expect(modified.default_url_options).to eql(url_opts)
      expect(modified).to eql(dummy_app)
    end

    it 'should allow overriding the routes for the application' do
      dummy_routes = {root: '/', other_route: '/other/route', another_route: '/another/route'}
      modified = Excursion::Pool::DSL.block_eval(dummy_app) do
        routes dummy_routes
      end
      dummy_routes.each do |key,val|
        expect(modified.route(key).path.spec.to_s).to eql(val)
      end
      expect(modified).to eql(dummy_app)
    end

    it 'should allow adding a route to the application' do
      dummy_routes = {root: '/', other_route: '/other/route', another_route: '/another/route'}
      modified = Excursion::Pool::DSL.block_eval(dummy_app) do
        dummy_routes.each do |key,val|
          route key, val
        end
      end
      dummy_routes.each do |key,val|
        expect(modified.route(key).path.spec.to_s).to eql(val)
      end
      expect(modified).to eql(dummy_app)
    end
  end

  context 'when an application is not provided' do
    it 'should create a new application' do
      expect(Excursion::Pool::DSL.block_eval { name 'dummy' }).to be_an_instance_of(Excursion::Pool::Application)
    end

    it 'should require setting the name of the application' do
      expect(Excursion::Pool::DSL.block_eval { name 'dummy' }.name).to eql('dummy')
      expect { Excursion::Pool::DSL.block_eval }.to raise_exception(RuntimeError)
    end

    it 'should allow setting the default_url_options for the application' do
      url_opts = {host: 'dummy.local', port: 1234}
      modified = Excursion::Pool::DSL.block_eval do
        name 'dummy'
        default_url_options url_opts
      end
      expect(modified.default_url_options).to eql(url_opts)
    end

    it 'should allow setting the routes for the application' do
      dummy_routes = {root: '/', other_route: '/other/route', another_route: '/another/route'}
      modified = Excursion::Pool::DSL.block_eval do
        name 'dummy'
        routes dummy_routes
      end
      dummy_routes.each do |key,val|
        expect(modified.route(key).path.spec.to_s).to eql(val)
      end
    end

    it 'should allow adding a route to the application' do
      dummy_routes = {root: '/', other_route: '/other/route', another_route: '/another/route'}
      modified = Excursion::Pool::DSL.block_eval do
        name 'dummy'
        dummy_routes.each do |key,val|
          route key, val
        end
      end
      dummy_routes.each do |key,val|
        expect(modified.route(key).path.spec.to_s).to eql(val)
      end
    end
  end


end
