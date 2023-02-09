require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::Package" do
  it "emits pkg resources" do
    catalog = resource_catalog("package { 'cowsay': ensure => present }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']).to include('pkg')
  end

  it "maps absent/purged to uninstalled" do
    catalog = resource_catalog("Package { provider => 'apt' } package { 'cowsay': ensure => absent; 'emacs': ensure => 'purged'; }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    graph['resources']['pkg'].each do |res|
      expect(res).to include('state' => 'uninstalled')
    end
  end

  it "fails on unsupported ensure values" do
    %w{1.3.1-5 latest 10bpo81 held}.each do |ensure_value|
      Puppet.expects(:err).with(regexp_matches(/cannot be translated/)).twice
      catalog = resource_catalog("Package { provider => 'apt' } package { 'cowsay': ensure => '#{ensure_value}' }")
      graph = PuppetX::CatalogTranslation.to_mgmt(catalog)

      # become 'exec puppet yamlresource' through the workaround
      expect(graph['resources']).to_not include('pkg')
      expect(graph['resources']).to     include('pippet')
    end
  end
end
