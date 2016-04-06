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
