require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::Group" do
  it "accepts ensure values of present and absent" do
    catalog = resource_catalog("group { 'yes': ensure => present; 'no': ensure => absent }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['group'][0]['state']).to be == "exists"
    expect(graph['resources']['group'][1]['state']).to be == "absent"
  end

  it "carries the gid parameter" do
    catalog = resource_catalog("group { 'specgroup': gid => 1001 }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['group'][0]['gid']).to be == 1001
  end
end
