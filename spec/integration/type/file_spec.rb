require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::File" do
  it "adds a trailing slash to paths of directories" do
    catalog = resource_catalog("file { '/tmp/spec_dir': ensure => 'directory' }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['file'][0]).to include('path' => '/tmp/spec_dir/')
  end

  it "maps present/file/directory to exists" do
    catalog = resource_catalog("file { '/a': ensure => present; '/b': ensure => file; '/c': ensure => directory; }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    graph['resources']['file'].each do |res|
      expect(res).to include('state' => 'exists')
    end
  end

  it "maps directory sources to the content parameter" do
    catalog = resource_catalog("file { '/tmp/spec_dir': ensure => 'directory', source => '/tmp/spec_source' }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['file'][0]).to include('content' => '/tmp/spec_source')
  end

  it "reports an error when a file source is a URL" do
    catalog = resource_catalog("file { '/tmp/spec_dir': ensure => 'directory', source => 'puppet:///spec/dir' }")

    # ignore Puppet 3 resource defaults:
    Puppet.stubs(:err).with(regexp_matches(/ignore source permissions/))

    Puppet.expects(:err).with(regexp_matches(/puppet fileserver URL/))
    Puppet.expects(:err).with(regexp_matches(/cannot be translated natively/))

    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']).to_not include 'file'
    expect(graph['resources']).to     include 'pippet'
  end

  it "reports an error when multiple sources are specified" do
    catalog = resource_catalog("file { '/tmp/spec_dir':
                                  ensure => 'directory',
                                  source => [ '/tmp/source1', '/tmp/source2', ],
                                }")

    # ignore Puppet 3 resource defaults:
    Puppet.stubs(:err).with(regexp_matches(/ignore source permissions/))

    Puppet.expects(:err).with(regexp_matches(/multiple sources/))
    Puppet.expects(:err).with(regexp_matches(/cannot be translated natively/))

    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']).to_not include 'file'
    expect(graph['resources']).to     include 'pippet'
  end
end
