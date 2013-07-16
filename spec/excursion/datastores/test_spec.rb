require 'spec_helper'
require 'excursion/datastores/test'

describe 'Excursion::Datastores::Test' do

  subject do
    Excursion::Datastores::Test.new
  end


  describe '::new' do
    it 'should not require pool data' do
      expect { Excursion::Datastores::Test.new }.to_not raise_exception
      expect { Excursion::Datastores::Test.new nil }.to_not raise_exception
    end

    it 'should optionally accept dummy pool data' do
      expect { Excursion::Datastores::Test.new {} }.to_not raise_exception
    end
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
      it 'should return a dummy application' do
        subject.read('non_existent_key').should be_an_instance_of(Excursion::Pool::DummyApplication)
      end
    end

    context 'when the requested key exists' do
      it 'should return the value of the requested key' do
        Excursion::Specs::Mocks::SIMPLE_VALUES.each do |key,val|
          subject.write(key, val)
          expect(subject.read(key)).to eql(val)
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

    it 'should return the value of the added key' do
      subject.write('test_key', 'testval').should == 'testval'
    end
  end

  context '#delete' do
    describe 'key' do
      it 'should be required' do
        expect { subject.delete }.to raise_exception(ArgumentError)
      end
    end
    
    it 'should remove the key from the datastore' do
      subject.write('key1', Excursion::Specs::Mocks::SIMPLE_VALUES['key1'])
      subject.read('key1').should eql(Excursion::Specs::Mocks::SIMPLE_VALUES['key1'])
      subject.delete('key1')
      subject.read('key1').should_not eql(Excursion::Specs::Mocks::SIMPLE_VALUES['key1'])
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
