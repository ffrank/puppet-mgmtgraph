require 'spec_helper'

describe "PuppetX::CatalogTranslation" do
  subject { PuppetX::CatalogTranslation }
  let(:empty_catalog) { Puppet::Resource::Catalog.new }

  describe "::to_mgmt" do
    let(:file_catalog) do
      result = Puppet::Resource::Catalog.new
      result.add_resource(Puppet::Type.type(:file).new(
        :name => '/tmp/spec',
        :ensure => :absent
      ))
      result
    end
    let(:bucket_catalog) do
      result = Puppet::Resource::Catalog.new
      result.add_resource(Puppet::Type.type(:filebucket).new(
        :name => 'this will not translate'
      ))
      result
    end
    let(:edge_catalog) do
      result = Puppet::Resource::Catalog.new
      result.add_resource(Puppet::Type.type(:file).new(
        :name => '/tmp/spec1',
        :ensure => :absent
      ))
      result.add_resource(Puppet::Type.type(:file).new(
        :name => '/tmp/spec2',
        :ensure => :absent,
        :require => 'File[/tmp/spec1]'
      ))
      result.add_resource(Puppet::Type.type(:notify).new(
        :name => 'this will not translate',
        :require => 'File[/tmp/spec1]'
      ))
      result
    end

    before :each do
      PuppetX::CatalogTranslation::Type.clear
    end

    it "always generates a header" do
      result = subject.to_mgmt(empty_catalog)
      expect(result).to include 'graph'
      expect(result).to include 'comment'
    end

    it "loads specific translators for resource types" do
      PuppetX::CatalogTranslation::Type.expects(:translation_for).with(:file)
      subject.to_mgmt(file_catalog)
    end

    it "does not include dropped resources in the result hash" do
      PuppetX::CatalogTranslation::Type.new(:filebucket) { emit nil }
      result = subject.to_mgmt(bucket_catalog)
      expect(result['resources']).to_not include 'notify'
      expect(result['resources']).to_not include 'exec'
    end

    it "keeps dependency edges between supported resources" do
      result = subject.to_mgmt(edge_catalog)
      expect(result['edges'][0]).to include(
        'from' => { 'kind' => 'file', 'name' => '/tmp/spec1' },
        'to'   => { 'kind' => 'file', 'name' => '/tmp/spec2' },
      )
    end

    it "converts ruby symbols in the result to strings" do
      subject.expects(:desymbolize)
      subject.to_mgmt(empty_catalog)
    end
  end

  describe "::stats" do
    it "makes sure to purge the error log" do
      PuppetX::CatalogTranslation::Type.expects(:reset_error_log!)
      PuppetX::CatalogTranslation::Type.expects(:dump_error_log)
      subject.stats(empty_catalog)
    end
  end

  describe "::desymbolize" do
    { 'a string' => 'spec',
      'a symbol' => :spec,
      'an array of strings' => %w{spec test array},
      'an array of symbols' => [:spec, :test, :array],
      'a hash of strings' => { 'k' => 'v', 'x' => 'v' },
      'a hash of symbols' => { :k => :v, :x => :y },
      'a complex structure' => { :k => [ :a, :b ] } }.each do |description,value|
      context "when given #{description}" do
        it "returns strings only" do
          result = subject.desymbolize(value)
          if result.respond_to? :to_a
            result = result.to_a
          end
          [result].flatten.each do |element|
            expect(element).to be_a String
          end
        end
      end
    end
  end

  describe "::set_mode" do
    it "accepts value :optimistic" do
      expect { subject.set_mode(:optimistic) }.to_not raise_error
    end

    it "accepts value :conservative" do
      expect { subject.set_mode(:conservative) }.to_not raise_error
    end

    it "does not accept unknown parameter values" do
      [ :great, :weird, :amazing, :elastic ].each do |param|
        expect { subject.set_mode(param) }.to raise_error(/invalid .* mode/)
      end
    end
  end

  describe "::get_catalog" do
    let(:catalog_face) { Puppet::Face[:catalog, "0.0"] }

    context "when a manifest file was passed on the command line" do
      before(:each) { Puppet[:manifest] = '/path/to/spec.rb' }

      it "does not touch the catalog indirection terminus" do
        catalog_face.expects(:find)
        catalog_face.expects(:set_terminus).never
        expect { subject.get_catalog }.to raise_error(Puppet::Error)
      end
    end

    context "when inline code was passed on the command line" do
      before(:each) { Puppet[:code] = 'file { "/tmp/specfile": ensure => "file" }' }

      it "does not use the catalog face" do
        catalog_face.expects(:find).never
        subject.get_catalog
      end
    end

    context "when no code is passed on he command line" do
      it "does not use the catalog face" do
        catalog_face.expects(:find).never
        subject.get_catalog
      end
    end
  end

end
