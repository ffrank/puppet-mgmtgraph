require 'spec_helper'

describe "PuppetX::CatalogTranslation" do
  before :each do
    ensure_core_module 'cron'
  end

  it "only keeps edges between supported resources" do
    catalog = resource_catalog("file { '/tmp/foo': } -> file { '/tmp/bar': } -> resources { 'user': }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['edges']).to include({"name"=>"File[/tmp/foo] -> File[/tmp/bar]",
                                       "from"=>{"kind"=>"file", "name"=>"/tmp/foo"},
                                       "to"=>{"kind"=>"file", "name"=>"/tmp/bar"}})
    graph['edges'].each do |edge|
      expect(edge['from']).to_not include( { 'name' => 'user' } )
      expect(edge['to']  ).to_not include( { 'name' => 'user' } )
    end
  end

  it "uses deterministic names for edges that do not change regardless of context" do
    manifest = "file { '/tmp/foo': } -> file { '/tmp/bar': } -> resources { 'user': }"
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
    expect(graph['resources']['svc'][0]).to_not include('startup')
  end

  it "generates `exec puppet yamlresource` vertices for untranslatable resources" do
    catalog = resource_catalog("cron { 'spec': ensure => present, command => 'rspec spec', user => 'root', minute => 9 }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']).to_not include('cron')
    expect(graph['resources']).to     include('exec')
    expect(graph['resources']['exec'][0]['cmd']).to match(/^puppet yamlresource cron 'spec'/)
  end


  it "drops relationship metaparams but keeps the relationship" do
    ensure_core_module 'host'
    catalog = resource_catalog('host { "a": before => Host["b"] } host { "b": }')
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['exec'][0]['cmd']).to_not include('before')
    expect(graph['edges']).to include(
      {"name"=>"Host[a] -> Host[b]",
         "from"=>{"kind"=>"exec", "name"=>"Host:a"},
         "to"=>{"kind"=>"exec", "name"=>"Host:b"}
      }
    )
  end

  context "in conservative mode" do
    before :each do
      PuppetX::CatalogTranslation.stubs(:mode).returns(:conservative)
    end

    it "generates `exec puppet yamlresource` vertices for problematic resources" do
      catalog = resource_catalog("service { 'spec': hasrestart => true, provider => 'systemd' }")
      graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
      expect(graph['resources']).to_not include('svc')
      expect(graph['resources']).to     include('exec')
      expect(graph['resources']['exec'][0]['cmd']).to match(/^puppet yamlresource service 'spec'/)
    end

    it "preserves edges from and to wrapped resources" do
      catalog = resource_catalog("file { '/tmp/foo': } -> service { 'spec': hasrestart => true, provider => 'systemd' }")
      graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
      expect(graph['edges']).to include({"name"=>"File[/tmp/foo] -> Service[spec]",
                                         "from"=>{"kind"=>"exec", "name"=>"File:/tmp/foo"},
                                         "to"=>{"kind"=>"exec", "name"=>"Service:spec"}})
      graph['edges'].each do |edge|
        expect(edge['from']).to_not include( { 'kind' => 'svc' } )
        expect(edge['from']).to_not include( { 'kind' => 'file' } )
        expect(edge['to']  ).to_not include( { 'kind' => 'svc' } )
        expect(edge['to']  ).to_not include( { 'kind' => 'file' } )
      end
    end
  end

  context "in stats mode" do
    after :all do
      # make sure the active error log does not contaminate other tests
      PuppetX::CatalogTranslation::Type.disable_error_log!
    end

    it "still loads translators for all resources" do
      ensure_core_module 'host'
      catalog = resource_catalog("file { [ '/a', '/b', '/c' ]: } -> host { [ 'x', 'y' ]: }")
      PuppetX::CatalogTranslation::Type.expects(:translation_for).with(:file).times(3)
      PuppetX::CatalogTranslation::Type.expects(:translation_for).with(:host).times(2)
      PuppetX::CatalogTranslation::Type.stubs(:translation_for).with(:whit)
      PuppetX::CatalogTranslation.stats(catalog)
    end
  end
end
