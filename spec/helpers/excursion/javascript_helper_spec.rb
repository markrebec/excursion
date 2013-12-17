require 'spec_helper'

describe Excursion::JavascriptHelper do
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
  
  describe "#render_excursion_javascript_helpers" do
    it "should return an ActiveSupport::SafeBuffer string" do
      expect(helper.render_excursion_javascript_helpers).to be_an_instance_of(ActiveSupport::SafeBuffer)
    end

    it "should return a script tag which loads the pool" do
      expect(helper.render_excursion_javascript_helpers.match(/\A<script.*>Excursion\.loadPool\(.*\);<\/script>\Z/)[0]).to_not be_nil
    end

    it "should base64 encode the dumped route pool" do
      pool = helper.render_excursion_javascript_helpers.match(/\A<script.*>Excursion\.loadPool\('(.*)'\);<\/script>\Z/)[1]
      expect(JSON.parse(Base64.decode64(pool))).to be_an_instance_of(Array)
    end
  end
end
