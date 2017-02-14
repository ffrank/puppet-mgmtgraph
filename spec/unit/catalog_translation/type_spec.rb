require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type" do
  before :each do
    PuppetX::CatalogTranslation::Type.clear
  end

  describe "#translate!" do
    it "emits a warning about unhandled resource attributes" do
      translator = PuppetX::CatalogTranslation::Type.translation_for(:service)
      resource = Puppet::Type.type(:service).new(:name => 'spec', :hasrestart => true, :provider => 'systemd' )
      Puppet.expects(:warning).with(regexp_matches /cannot translate.*hasrestart/)
      translator.translate!(resource)
    end

    it "emits no warning for ignored resource attributes" do
      translator = PuppetX::CatalogTranslation::Type.translation_for(:service)
      resource = Puppet::Type.type(:service).new(:name => 'spec', :loglevel => :notice, :provider => 'systemd' )
      Puppet.expects(:warning).never
      translator.translate!(resource)
    end

    it "emits no warning for catch-all translators" do
      PuppetX::CatalogTranslation::Type.new :notify do
        catch_all
      end
      resource = Puppet::Type.type(:notify).new(:name => 'spec', :message => 'this should not carp', :withpath => true)
      translator = PuppetX::CatalogTranslation::Type.translation_for(:notify)
      Puppet.expects(:warning).never
      translator.translate!(resource)
    end
  end

  describe "::translation_for" do
    it "loads the default translator if that has not yet happened" do
      PuppetX::CatalogTranslation::Type.expects(:load_translator).with(:default_translation)
      PuppetX::CatalogTranslation::Type.expects(:load_translator).with(:file)
      PuppetX::CatalogTranslation::Type.translation_for(:file)
    end

    it "returns the default translator if there is no specific one" do
      default_translation = PuppetX::CatalogTranslation::Type.translation_for(:default_translation)
      cron_translation = PuppetX::CatalogTranslation::Type.translation_for(:cron)
      expect(cron_translation).to be default_translation
    end
               
  end

  describe "#unsupported" do
    it "sends warnings to the logging subsystem" do
      translator = PuppetX::CatalogTranslation::Type.translation_for(:service)
      Puppet.expects(:warning)
      translator.send :unsupported, "This is a warning"
    end

    it "sends errors to the logging subsystem" do
      translator = PuppetX::CatalogTranslation::Type.translation_for(:service)
      Puppet.expects(:err)
      translator.send :unsupported, "This is an error", :err
    end

    it "does not accept invalid message levels" do
      translator = PuppetX::CatalogTranslation::Type.translation_for(:service)
      expect {translator.send :unsupported, "This is an error", :initialize}.to raise_error(/initialize/)
    end
  end
end
