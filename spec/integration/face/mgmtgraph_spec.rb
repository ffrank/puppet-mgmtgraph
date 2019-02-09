require 'spec_helper.rb'

describe "Puppet::Face::Mgmtgraph" do
  it "refuses to run with Puppet under version 4" do
    Puppet.stubs(:version).returns('3.8.1')
    expect {
      Puppet::Face['mgmtgraph',:current].find
    }.to raise_error(Puppet::Error)
  end

  it "runs fine with Puppet 4 and above" do
    Puppet.stubs(:version).returns('4.10.0')
    catalog = compile_catalog('file { "/tmp/a": }')
    PuppetX::CatalogTranslation.stubs(:get_catalog).returns(catalog)
    expect {
      Puppet::Face['mgmtgraph',:current].find
    }.to_not raise_error
  end
end
