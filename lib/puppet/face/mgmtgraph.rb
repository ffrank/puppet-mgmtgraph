require 'puppet/face'
require 'puppetx/catalog_translation'

Puppet::Face.define(:mgmtgraph, '0.0.1') do
  
  license "Apache 2"
  copyright "Felix Frank", 2016
  author "Felix Frank <felix.frank@alumni.tu-berlin.de>"
  summary "Generate a catalog and generate a mgmt compatible graph from it."

  action :print do
    default
    summary "Print the graph in YAML format"

    when_invoked do |*args|
      catalog = Puppet::Face[:catalog, "0.0"].find
      graph = PuppetX::CatalogTranslation.to_mgmt(catalog.to_ral)
      puts YAML.dump PuppetX::CatalogTranslation.desymbolize(graph)
    end
  end
end
