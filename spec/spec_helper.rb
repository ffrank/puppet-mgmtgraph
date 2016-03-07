# spec_helper.rb
#
# general requirements for mgmtgraph specs

require 'puppet'
require 'puppet/face'
gem 'rspec', '>=3.0.0'
require 'rspec/expectations'

RSpec.configure do |config|
  config.mock_with :mocha
end
