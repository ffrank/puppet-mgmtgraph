require 'spec_helper'

describe "PuppetX::CatalogTranslation::Type" do
  before :each do
    PuppetX::CatalogTranslation::Type.clear
  end

  describe "#translate!" do
    context "when dealing with unhandled resource attributes" do
      let(:translator) { PuppetX::CatalogTranslation::Type.translation_for(:service) }
      let(:resource) { Puppet::Type.type(:service).new(:name => 'spec', :hasrestart => true, :provider => 'systemd' ) }

      it "emits an error" do
        Puppet.expects(:err).with(regexp_matches /cannot translate.*hasrestart/)
        Puppet.expects(:err).with(regexp_matches /cannot be translated natively/)
        translator.translate!(resource)
      end

      # this is icky: should actually be a test for "when translation is unclean"
      # but that is controlled by a private method -_-
      it "returns a pippet resource" do
        type, _ = translator.translate!(resource)
        expect(type).to equal(:pippet)
      end
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
      PuppetX::CatalogTranslation::Type.expects(:load_translator).with(:default_translation_to_pippet)
      PuppetX::CatalogTranslation::Type.expects(:load_translator).with(:default_translation)
      PuppetX::CatalogTranslation::Type.expects(:load_translator).with(:file)
      PuppetX::CatalogTranslation::Type.translation_for(:file)
    end

    it "returns the default translator if there is no specific one" do
      default_translation = PuppetX::CatalogTranslation::Type.translation_for(:default_translation_to_pippet)
      cron_translation = PuppetX::CatalogTranslation::Type.translation_for(:cron)
      expect(cron_translation).to be default_translation
    end
  end

  let(:translator) { PuppetX::CatalogTranslation::Type.translation_for(:service) }

  describe "#translation_warning" do
    it "calls #unsupported at warning level" do
      translator.expects(:unsupported).with(anything, :warning, nil)
      translator.send :translation_warning, "This is a spec warning"
    end

    it "marks the translation as unclean in conservative mode" do
      PuppetX::CatalogTranslation.stubs(:mode).returns(:conservative)
      translator.expects(:mark_as_unclean)
      translator.send :translation_warning, "This is a spec warning"
    end
  end

  describe "#translation_failure" do
    it "calls #unsupported at error level" do
      translator.expects(:unsupported).with(anything, :err, nil)
      translator.send :translation_failure, "This is a spec error"
    end

    it "marks the translation as unclean" do
      translator.expects(:mark_as_unclean)
      translator.send :translation_failure, "This is a spec error"
    end
  end

  describe "#unsupported" do
    it "sends warnings to the logging subsystem" do
      Puppet.expects(:warning)
      translator.send :unsupported, "This is a warning"
    end

    it "sends errors to the logging subsystem" do
      Puppet.expects(:err)
      translator.send :unsupported, "This is an error", :err
    end

    it "does not accept invalid message levels" do
      expect {translator.send :unsupported, "This is an error", :initialize}.to raise_error(/initialize/)
    end

    it "includes the value in the message if it was given" do
      Puppet.expects(:warning).with(regexp_matches(/this_is_a_test_string_and_should_appear/))
      translator.send :unsupported, "This is a warning", :warning, "value=this_is_a_test_string_and_should_appear"
    end
  end

end
