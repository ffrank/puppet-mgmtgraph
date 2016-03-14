require 'spec_helper'

describe "PuppetX::CatalogTranslation" do
  describe "::to_mgmt" do
    let(:empty_catalog) { Puppet::Resource::Catalog.new }
    let(:file_catalog) do
      result = Puppet::Resource::Catalog.new
      result.add_resource(Puppet::Type.type(:file).new(
        :name => '/tmp/spec',
        :ensure => :absent
      ))
      result
    end
    let(:notify_catalog) do
      result = Puppet::Resource::Catalog.new
      result.add_resource(Puppet::Type.type(:notify).new(
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

    it "always generates a header" do
      result = PuppetX::CatalogTranslation.to_mgmt(empty_catalog)
      expect(result).to include 'graph'
      expect(result).to include 'comment'
    end

    it "loads specific translators for resource types" do
      PuppetX::CatalogTranslation::Type.expects(:translation_for).with(:file)
      PuppetX::CatalogTranslation.to_mgmt(file_catalog)
    end

    it "does not include unsupported resources in the result hash" do
      # make sure that the file translator is not loaded
      PuppetX::CatalogTranslation::Type.expects(:load_translator).with(:file)
      result = PuppetX::CatalogTranslation.to_mgmt(file_catalog)
      expect(result['types']).to_not include 'file'
    end

    it "keeps dependency edges between supported resources" do
      result = PuppetX::CatalogTranslation.to_mgmt(edge_catalog)
      expect(result['edges'][0]).to include(
        'from' => { 'type' => 'file', 'name' => '/tmp/spec1' },
        'to'   => { 'type' => 'file', 'name' => '/tmp/spec2' },
      )
    end

    it "discards edges that connect to an ignored resource" do
      # make sure that no notify translator is loaded
      PuppetX::CatalogTranslation::Type.expects(:load_translator).with(:notify)
      result = PuppetX::CatalogTranslation.to_mgmt(edge_catalog)
      expect(result['edges'].length).to be 1
      expect(result['edges'][0]).to_not include(
        'to' => { 'type' => 'notify', 'name' => 'this will not translate' },
      )
    end

    it "converts ruby symbols in the result to strings" do
      PuppetX::CatalogTranslation.expects(:desymbolize)
      PuppetX::CatalogTranslation.to_mgmt(empty_catalog)
    end
  end

end
