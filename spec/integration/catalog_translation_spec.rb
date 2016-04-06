require 'spec_helper'

describe "PuppetX::CatalogTranslation" do
  it "only keeps edges between supported resources" do
    catalog = resource_catalog("file { '/tmp/foo': } -> file { '/tmp/bar': } -> resources { 'cron': }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['edges']).to_not be_empty
    expect(graph['edges'][0]['from']).to include('name' => '/tmp/foo')
    expect(graph['edges'][0]['to']).to   include('name' => '/tmp/bar')
    expect(graph['edges'].length).to be == 1
  end
end
