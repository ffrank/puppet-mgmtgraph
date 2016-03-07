require 'spec_helper.rb'

describe "puppet mgmtgraph" do

  # hardcoded in the mgmtgraph face
  let(:catalog_face_version) { "0.0.1" }

  subject { Puppet::Face[:mgmtgraph, "0"] }

  describe "print" do
    it "uses the find action to get the graph" do
      subject.expects :find
      YAML.expects :dump
      subject.print
    end
  end

  describe "find" do
    it "uses the find action of the catalog face" do
      Puppet::Face[:catalog, catalog_face_version].expects(:find).returns Puppet::Resource::Catalog.new
      expect(subject.find).to be_a Hash
    end
  end

end
