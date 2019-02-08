# A sample Gemfile
source "https://rubygems.org"

# weird hack, unclear why e.g. 'irb' needs this:
$:.unshift('lib')

# gem "rails"
gem "puppet", ENV['PUPPET_GEM_VERSION'] || '~> 6.2'
gem "puppetlabs_spec_helper"

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
