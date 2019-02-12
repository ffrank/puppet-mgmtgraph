require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type::Augeas" do
  before :each do
    ensure_core_module 'augeas'
  end

  it "refuses to translate a resource with no 'incl' parameter" do
    catalog = resource_catalog("augeas { 'test': changes => [ 'set /files/etc/hosts/0/canonical first' ] }")
    PuppetX::CatalogTranslation::Type.translation_for(:augeas).expects(:translation_failure).with(regexp_matches(/incl/))
    PuppetX::CatalogTranslation.to_mgmt(catalog)
  end
end
