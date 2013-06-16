require 'spec_helper'
require 'excursion/datasources/file'

describe 'Excursion::Datasources::File' do

  def fill_pool(file)
    File.open(file, 'w') do |f|
      f.write(Excursion::Specs::Fixtures::Datasources::POOL.to_yaml)
    end
  end

  context 'Initialization' do
    # TODO File should not depend on excursion configuration, we should be passing in the configured file path on init
    # rework these specs to represent that, then make the changes
    #before(:each) { Excursion.configure { |c| c.datasource_file = Dir.pwd } }
    
    it 'should require a path' do
      expect { Excursion::Datasources::File.new }.to raise_exception
      expect { Excursion::Datasources::File.new Dir.pwd }.to_not raise_exception
    end
  end

  describe '#read' do
    subject do
      fill_pool File.expand_path("../../../dummy/tmp/spec_pool.yml", __FILE__)
      Excursion::Datasources::File.new File.expand_path("../../../dummy/tmp/spec_pool.yml", __FILE__)
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
      before(:each) do
        @spec_pool = YAML.load_file(File.expand_path("../../../dummy/tmp/spec_pool.yml", __FILE__))
      end

      it 'should return the value of the requested key' do
        @spec_pool.each do |key,val|
          expect(subject.read(key)).to eql(val)
        end
      end
    end
  end

  describe '#write' do
    subject do
      fill_pool File.expand_path("../../../dummy/tmp/spec_pool.yml", __FILE__)
      Excursion::Datasources::File.new File.expand_path("../../../dummy/tmp/spec_pool.yml", __FILE__)
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
        expect { subject.write('test_key') }.to raise_exception
      end
    end

    context 'simple values' do
      it 'can be stored'
    end

    context 'complex structures' do
      it 'can be stored'
    end

    context 'ruby objects and classes' do
      it 'can be stored'
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
    it 'should require a key'
    it 'should remove the key from the datastore'
    it 'should return the value of the deleted key'
  end

end
