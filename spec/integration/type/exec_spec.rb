require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::Exec" do
  it "uses bash as the shell" do
    catalog = resource_catalog("exec { 'test': command => '/usr/bin/cowsay boo' }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['exec'][0]['shell']).to be == "/bin/bash"
    expect(graph['resources']['exec'][0]['watchshell']).to be == "/bin/bash"
    expect(graph['resources']['exec'][0]['ifshell']).to be == "/bin/bash"
  end

  it "uses a watchcommand to trigger the resource in Puppet's run interval" do
    catalog = resource_catalog("exec { 'test': command => '/usr/bin/cowsay boo' }")
    old_runinterval = Puppet[:runinterval]
    Puppet[:runinterval] = 3189
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    Puppet[:runinterval] = old_runinterval
    expect(graph['resources']['exec'][0]['watchcmd']).to match /sleep 3189 /
  end
end
