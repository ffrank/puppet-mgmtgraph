require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::Package" do
  it "emits pkg resources" do
    catalog = resource_catalog("package { 'cowsay': ensure => present }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']).to include('pkg')
  end

  it "maps absent/purged to uninstalled" do
    catalog = resource_catalog("package { 'cowsay': ensure => absent; 'emacs': ensure => 'purged'; }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    graph['resources']['pkg'].each do |res|
      expect(res).to include('state' => 'uninstalled')
    end
  end

  it "prints an error message about unsupported ensure values" do
    %w{1.3.1-5 latest held 10bpo81}.each do |ensure_value|
      Puppet.expects(:err).with(regexp_matches(/cannot be translated/))
      catalog = resource_catalog("package { 'cowsay': ensure => '#{ensure_value}' }")
      graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
      expect(graph['resources']['pkg'][0]).to include('state' => 'installed')
    end
  end
end
