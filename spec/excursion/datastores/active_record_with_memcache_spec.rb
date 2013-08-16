require 'spec_helper'
require 'excursion/datastores/active_record_with_memcache'

describe 'Excursion::Datastores::ActiveRecordWithMemcache' do
  
  def dalli_client
    @dalli_client ||= Dalli::Client.new dummy_pool, {namespace: 'excursion'}
  end

  def dummy_pool
    Excursion::Specs::DUMMY_MEMCACHE_SERVER
  end

  def fill_pool
    Excursion::RoutePool.all.each { |m| m.destroy }
    dalli_client.flush_all
    Excursion::Specs::Mocks::SIMPLE_VALUES.each do |key,val|
      dalli_client.set(key, val)
      Excursion::RoutePool.create key: key, value: val
    end
    dalli_client.set(Excursion::Datastores::Memcache::REGISTERED_KEYS, Excursion::Specs::Mocks::SIMPLE_VALUES.keys.map(&:to_s).join(','))
  end
  
  subject do
    fill_pool
    Excursion::Datastores::ActiveRecordWithMemcache.new dummy_pool
  end

  describe '#read' do
    describe 'key' do
      it 'should be required' do
        expect { subject.read }.to raise_exception
        expect { subject.read('test_key') }.to_not raise_exception
      end

      it 'should accept a symbol or string' do
        expect { subject.read('test_key') }.to_not raise_exception
        expect { subject.read(:test_key) }.to_not raise_exception
      end

      it 'should convert symbols to strings' do
        expect(subject.read(:key1)).to eql(subject.read('key1'))
      end
    end

    context 'when the requested key does not exist' do
      it 'should return nil' do
        subject.read('non_existent_key').should be_nil
      end
    end

    context 'when the requested key exists' do
      context 'in the cache' do
        it 'should return the value of the requested key' do
          Excursion::Specs::Mocks::SIMPLE_VALUES.each do |key,val|
            expect(dalli_client.get(key)).to eql(val)
            expect(subject.read(key)).to eql(val)
          end
        end
      end

      context 'in the database' do
        it 'should return the value of the requested key' do
          Excursion::Specs::Mocks::SIMPLE_VALUES.each do |key,val|
            dalli_client.delete(key)
            expect(dalli_client.get(key)).to be_nil
            expect(subject.read(key)).to eql(val)
          end
        end
      end
    end
  end

  describe '#write' do
    describe 'key' do
      it 'should be required' do
        expect { subject.write }.to raise_exception
      end

      it 'should accept a symbol or string' do
        expect { subject.write('str_key', 'strval') }.to_not raise_exception
        expect { subject.write(:sym_key, 'symval') }.to_not raise_exception
      end

      it 'should convert symbols to strings' do
        subject.write(:sym_key, 'symval')
        subject.read('sym_key').should == 'symval'
      end
    end

    describe 'value' do
      it 'should be required' do
        expect { subject.write('test_key') }.to raise_exception(ArgumentError)
      end
    end

    it 'should add the key to the datastore and set the value' do
      subject.write('test_key', 'testval')
      subject.read('test_key').should == 'testval'
    end
    
    it 'should add the key to the active record table and set the value' do
      subject.write('test_key', 'testval')
      Excursion::RoutePool.find_by(key: 'test_key').value.should eql('testval') if Excursion.rails4?
      Excursion::RoutePool.find_by_key('test_key').value.should eql('testval') if Excursion.rails3?
    end

    it 'should add the key to the cache and set the value' do
      subject.write('test_key', 'testval')
      dalli_client.get('test_key').should eql('testval')
    end

    it 'should return the value of the added key' do
      subject.write('test_key', 'testval').should == 'testval'
    end
  end

  describe '#delete' do
    before(:each) do
      fill_pool
    end

    describe 'key' do
      it 'should be required' do
        expect { subject.delete }.to raise_exception(ArgumentError)
      end
    end
    
    it 'should remove the key from the datastore' do
      subject.read('key1').should_not eql(nil)
      subject.delete('key1')
      subject.read('key1').should be(nil)
    end
    
    it 'should remove the key from the active record table' do
      Excursion::RoutePool.find_by(key: 'key1').should_not be_nil if Excursion.rails4?
      Excursion::RoutePool.find_by_key('key1').should_not be_nil if Excursion.rails3?
      subject.delete('key1')
      Excursion::RoutePool.find_by(key: 'key1').should be_nil if Excursion.rails4?
      Excursion::RoutePool.find_by_key('key1').should be_nil if Excursion.rails3?
    end

    it 'should remove the key from the cache if it exists' do
      dalli_client.get('key1').should_not be_nil
      subject.delete('key1')
      dalli_client.get('key1').should be_nil
    end

    it 'should return the value of the deleted key if it exists' do
      keyval = subject.read('key1')
      subject.delete('key1').should eql(keyval)
    end

    it 'should return nil if the deleted key does not exist' do
      subject.delete('non_existent_key').should eql(nil)
    end
  end
  
  describe '#all' do
    it 'should return a hash of all the registered keys and their values' do
      Excursion::Specs::Mocks::SIMPLE_VALUES.each do |k,v|
        expect(subject.all[k.to_sym]).to eql(v)
      end
    end
  end

end
