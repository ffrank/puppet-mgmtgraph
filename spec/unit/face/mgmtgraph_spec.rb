require 'spec_helper.rb'

describe "puppet mgmtgraph" do

  # hardcoded in the mgmtgraph face
  let(:catalog_face_version) { "0.0.1" }

  subject { Puppet::Face[:mgmtgraph, "0"] }

  describe "print" do
    it "uses the find action to get the graph" do
      subject.expects :find
      YAML.expects :dump
      subject.print
    end
  end

  describe "find" do
    it "uses the find action of the catalog face" do
      Puppet::Face[:catalog, catalog_face_version].expects(:find).returns Puppet::Resource::Catalog.new
      expect(subject.find).to be_a Hash
    end

    it "sends the catalog to the Catalog_Translation module" do
      Puppet::Face[:catalog, catalog_face_version].stubs(:find).returns Puppet::Resource::Catalog.new
      PuppetX::CatalogTranslation.expects(:to_mgmt)
      subject.find
    end

    it "sets the translation mode to optimistic by default" do
      Puppet::Face[:catalog, catalog_face_version].stubs(:find).returns Puppet::Resource::Catalog.new
      PuppetX::CatalogTranslation.expects(:set_mode).with(:optimistic)
      subject.find
    end

    it "sets the translation mode to conservative" do
      Puppet::Face[:catalog, catalog_face_version].stubs(:find).returns Puppet::Resource::Catalog.new
      PuppetX::CatalogTranslation.expects(:set_mode).with(:conservative)
      subject.find(:conservative => true)
    end
  end

  describe "stats" do

    after :all do
      # make sure the active error log does not contaminate other tests
      PuppetX::CatalogTranslation::Type.disable_error_log!
    end

    let(:empty_catalog) { Puppet::Resource::Catalog.new }

    it "retrieves a catalog" do
      PuppetX::CatalogTranslation.expects(:get_catalog).returns(empty_catalog)
      subject.stats
    end

    it "invokes the catalog translation module's stats method" do
      PuppetX::CatalogTranslation.expects(:get_catalog).returns(empty_catalog)
      PuppetX::CatalogTranslation.expects(:stats)
      subject.stats
    end
  end

end
