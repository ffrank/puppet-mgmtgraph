# spec_helper.rb
#
# general requirements for mgmtgraph specs

require 'puppetlabs_spec_helper/puppet_spec_helper'
require 'puppet/face'
require 'puppetx/catalog_translation'

RSpec.configure do |config|
  config.mock_with :mocha

  Puppet::Test::TestHelper.initialize

  config.before :all do
    Puppet::Test::TestHelper.before_all_tests()
  end

  config.after :all do
    Puppet::Test::TestHelper.after_all_tests()
  end

  config.before :each do
    Puppet::Test::TestHelper.before_each_test()
  end

  config.after :each do
    Puppet::Test::TestHelper.after_each_test()
  end
end

def resource_catalog(manifest)
  compile_catalog(manifest).to_ral
end

def compile_catalog(manifest)
  Puppet[:code] = manifest
  node = Puppet::Node.new('spec.example.net')
  Puppet::Parser::Compiler.compile(node)
end

def ensure_core_module(core_module)
  return if Gem::Version.new(Puppet.version) < Gem::Version.new('6.0.0')
  face = Puppet::Face['module','1.0.0']
  # silly hack to make sure we have a temporary vardir, although the
  # location is in the environment path, which is bonkers
  Puppet[:vardir] = Puppet[:environmentpath] + "/vardir"
  face.install("puppetlabs-#{core_module}_core", { :target_dir => Puppet[:environmentpath] + "/production/modules" })
end
