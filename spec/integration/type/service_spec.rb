require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::Service" do
  it "emits an svc" do
    catalog = resource_catalog("service { 'test': ensure => 'running', provider => 'systemd' }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']).to include('svc')
  end
end
