require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::DefaultTranslationToPippet" do
  let(:manifest) { "cron { 'test': ensure => 'present', command => 'echo spec' }" }

  it "emits an pippet node" do
    catalog = resource_catalog(manifest)
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']).to include('pippet')
  end

  it "uses a polling interval to trigger the resource in Puppet's run interval" do
    catalog = resource_catalog(manifest)
    old_runinterval = Puppet[:runinterval]
    Puppet[:runinterval] = 3189
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    Puppet[:runinterval] = old_runinterval
    expect(graph['resources']['pippet'][0]['pollint']).to be == 3189
  end

  it "uses the original resource type as a title prefix" do
    catalog = resource_catalog(manifest)
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['pippet'][0]['name']).to match /^Cron\[/
  end
end