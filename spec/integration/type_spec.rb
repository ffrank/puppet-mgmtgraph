require 'spec_helper'
require 'puppet/type/notify'

describe "PuppetX::CatalogTranslation::Type" do

  describe "::dump_error_log" do
    before :each do
      PuppetX::CatalogTranslation::Type.reset_error_log!
    end

    after :all do
      PuppetX::CatalogTranslation::Type.disable_error_log!
    end

    it "produces error messages that were raised during translation" do
      catalog = resource_catalog("file { '/a': purge => true }")
      PuppetX::CatalogTranslation.to_mgmt(catalog)
      expect(PuppetX::CatalogTranslation::Type.dump_error_log.lines).to include(/purge/)
    end

    it "consolidates error messages that were raised during translation" do
      catalog = resource_catalog("file { [ '/a', '/b', '/c' ]: purge => true }")
      PuppetX::CatalogTranslation.to_mgmt(catalog)
      output = PuppetX::CatalogTranslation::Type.dump_error_log.lines
      expect(output.grep(/purge/).count).to be == 1
      expect(output.grep(/purge/)[0]).to include('3x')
    end

    it "includes messages about unsupported resource types" do
      catalog = resource_catalog("schedule { 'spec': period => hourly, repeat => 2 }")
      PuppetX::CatalogTranslation.to_mgmt(catalog)
      output = PuppetX::CatalogTranslation::Type.dump_error_log.lines
      output *= "\n"
      expect(output).to include('Schedule')
    end
  end

  describe ".spawn" do
    it "drops parameters that yield a nil value" do
      type = PuppetX::CatalogTranslation::Type.new(:spec) { spawn(:unwanted) { nil } }
      out_type, params = type.translate!(Puppet::Type::Notify.new(:name => "spec-notify"))
      expect(params).to_not include(:unwanted)
    end
  end

end
