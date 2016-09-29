require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::Notify" do
  it "emits a msg resource" do
    catalog = resource_catalog("notify { 'spec': message => 'spec message' }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']).to include('msg')
  end

  it "renders loglevels into priorities" do
    catalog = resource_catalog("notify { 'spec': message => 'spec message', loglevel => 'emerg' }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['msg'][0]).to include('priority' => 'Emerg')
  end
end
