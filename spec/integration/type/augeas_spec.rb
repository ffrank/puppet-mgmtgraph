require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::Augeas" do
  it "refuses to translate a resource with no 'incl' parameter" do
    catalog = resource_catalog("augeas { 'test': changes => [ 'set /files/etc/hosts/0/canonical first' ] }")
    PuppetX::CatalogTranslation::Type.translation_for(:augeas).expects(:translation_failure).with(regexp_matches(/incl/))
    PuppetX::CatalogTranslation.to_mgmt(catalog)
  end

  it "ignores changes that do not use the 'set' command" do
    changes = [ 'set /path/to/node new_value', 'rm /path/to/obsolete/node', 'mv /old/node /new/node' ]
    catalog = resource_catalog("augeas { 'test': changes => #{changes} }")
    graph = PuppetX::CatalogTranslation.to_mgmt(catalog)
    expect(graph['resources']['augeas'][0]['sets'].count).to be == 1
    expect(graph['resources']['augeas'][0]['sets'][0]['path']).to be == '/path/to/node'
  end
end
