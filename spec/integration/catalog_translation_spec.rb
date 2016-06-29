require 'spec_helper'

describe "PuppetX::CatalogTranslation" do
  it "only keeps edges between supported resources" do
    catalog = resource_catalog("file { '/tmp/foo': } -> file { '/tmp/bar': } -> resources { 'cron': }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['edges']).to include({"name"=>"File[/tmp/foo] -> File[/tmp/bar]",
                                       "from"=>{"kind"=>"file", "name"=>"/tmp/foo"},
                                       "to"=>{"kind"=>"file", "name"=>"/tmp/bar"}})
    graph['edges'].each do |edge|
      expect(edge['from']).to_not include( { 'name' => 'cron' } )
      expect(edge['to']  ).to_not include( { 'name' => 'cron' } )
    end
  end

  it "uses deterministic names for edges that do not change regardless of context" do
    manifest = "file { '/tmp/foo': } -> file { '/tmp/bar': } -> resources { 'cron': }"
    graph = PuppetX::CatalogTranslation.to_mgmt(resource_catalog(manifest))
    edge = graph['edges'][0]

    [ [ "file { [ '/a', '/b' ]: } ->", "" ],
      [ "file { [ '/a', '/b' ]: } ->", "-> file { '/c': }" ],
      [ "file { [ '/a', '/b' ]: } ->", "<- file { '/c': }" ],
      [ "file { [ '/a', '/b' ]: } <-", "<- file { '/c': }" ],
      [ "", "<- file { [ '/a', '/b', '/c' ]: }" ],
      [ "", "-> file { [ '/a', '/b', '/c' ]: }" ]
    ].each do |pre, post|
      graph = PuppetX::CatalogTranslation.to_mgmt(resource_catalog(pre + manifest + post))
      expect(graph['edges']).to_not be_empty
      expect(graph['edges']).to include(edge)
    end
  end

  it "only includes renamed attributes in output if the original was in the input" do
    catalog = resource_catalog("service { 'apache2': ensure => running }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['service'][0]).to_not include('startup')
  end
end
