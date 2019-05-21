require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::Mount" do
  before :each do
    ensure_core_module 'mount'
  end

  { "device" => [ "device", "/dev/sda" ],
    "fstype" => [ "type", "ext4" ],
    "dump" => [ "freq", 0 ],
    "pass" => [ "passno", 2 ] }.each do |param,info|
      
    mgmt_param = info[0]
    value = info[1]

    it "carries the supported parameter #{param}" do
      # inspect helpfully quotes strings
      catalog = resource_catalog("mount { '/mnt/spec': #{param} => #{value.inspect} }")
      graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
      expect(graph['resources']['mount'][0][mgmt_param]).to be == value
    end
  end

  it "accepts flag-style options" do
    catalog = resource_catalog("mount { '/mnt/spec': options => 'noatime' }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['mount'][0]['options']).to include("noatime")
  end

  it "accepts key-value type options" do
    catalog = resource_catalog("mount { '/mnt/spec': options => 'errors=panic' }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['mount'][0]['options']).to include("errors" => "panic")
  end

  it "accepts lists of options" do
    catalog = resource_catalog("mount { '/mnt/spec': options => 'noatime,nobarrier,errors=panic' }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['mount'][0]['options']).to include("noatime")
    expect(graph['resources']['mount'][0]['options']).to include("nobarrier")
    expect(graph['resources']['mount'][0]['options']).to include("errors" => "panic")
  end
end
