require 'spec_helper'
require 'excursion/datasources/memcache'

describe 'Excursion::Datasources::Memcache' do

  def fill_pool(server)
    dc = Dalli::Client.new(server, {namespace: 'excursion'})
    Excursion::Specs::Fixtures::Datasources::POOL.each do |k,v|
      dc.write(k,v)
    end
  end

  context 'Initialization' do
    # TODO Memcache should not depend on excursion configuration, we should be passing in the configured file path on init
    # rework these specs to represent that, then make the changes
    #before(:each) { Excursion.configure { |c| c.datasource_file = Dir.pwd } }
    
    it 'should require a path' do
      expect { Excursion::Datasources::Memcache.new }.to raise_exception(Excursion::DatasourceConfigurationError)
      expect { Excursion::Datasources::Memcache.new 'localhost:11211' }.to_not raise_exception
    end
  end

  describe '#read' do
    subject do
      fill_pool 'localhost:11211'
      Excursion::Datasources::Memcache.new 'localhost:11211'
    end

    describe 'key' do
      it 'should be required' do
        expect { subject.read }.to raise_exception
        expect { subject.read('key1') }.to_not raise_exception
      end

      it 'should accept a symbol or string' do
        expect { subject.read('key1') }.to_not raise_exception
        expect { subject.read(:key1) }.to_not raise_exception
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
      it 'should return the value of the requested key' do
        Excursion::Specs::Fixtures::Datasources::POOL.each do |key,val|
          expect(subject.read(key)).to eql(val)
        end
      end
    end
  end

  describe '#write' do
    subject do
      fill_pool 'localhost:11211'
      Excursion::Datasources::Memcache.new 'localhost:11211'
    end
    
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

    it 'should return the value of the added key' do
      subject.write('test_key', 'testval').should == 'testval'
    end
  end

  context '#delete' do
    subject do
      fill_pool 'localhost:11211'
      Excursion::Datasources::Memcache.new 'localhost:11211'
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

    it 'should return the value of the deleted key if it exists' do
      keyval = subject.read('key1')
      subject.delete('key1').should eql(keyval)
    end

    it 'should return nil if the deleted key does not exist' do
      subject.delete('non_existent_key').should eql(nil)
    end
  end

end
