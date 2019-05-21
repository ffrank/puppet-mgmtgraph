require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::User" do
  { "uid" => [ "uid", 1001 ],
    "home" => [ "homedir", "/home/spec" ],
    "allowdupe" => [ "allowduplicateuid", true ] }.each do |param,info|
      
    mgmt_param = info[0]
    value = info[1]

    it "carries the supported parameter #{param}" do
      # inspect helpfully quotes strings
      catalog = resource_catalog("user { 'spec': #{param} => #{value.inspect} }")
      graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
      expect(graph['resources']['user'][0][mgmt_param]).to be == value
    end
  end

  it "accepts simple string values for groups" do
    catalog = resource_catalog("user { 'spec': groups => 'specgroup' }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['user'][0]['groups']).to be == [ "specgroup" ]
  end

  it "accepts array values for groups" do
    catalog = resource_catalog("user { 'spec': groups => [ 'admingroup', 'specgroup' ] }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['user'][0]['groups']).to be == [ "admingroup", "specgroup" ]
  end

  it "accepts ensure values of present and absent" do
    catalog = resource_catalog("user { 'yes': ensure => present; 'no': ensure => absent }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['user'][0]['state']).to be == "exists"
    expect(graph['resources']['user'][1]['state']).to be == "absent"
  end

  it "renders numeric gid parameters to the gid parameter" do
    catalog = resource_catalog("user { 'spec': gid => 1001 }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['user'][0]['gid']).to be == 1001
  end

  it "renders string gid parameters to the group parameter" do
    catalog = resource_catalog("user { 'spec': gid => 'specgroup' }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['user'][0]['group']).to be == "specgroup"
  end
end
