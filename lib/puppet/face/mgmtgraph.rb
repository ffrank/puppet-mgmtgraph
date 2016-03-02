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
      graph = Puppet::Face[@name, @version].find
      puts YAML.dump graph
    end
  end

  action :find do
    summary "Return the graph in hash format"
    when_invoked do |*args|

      # suppress performance message from the compiler
      if Puppet[:log_level] == "notice"
        Puppet[:log_level] = "warning"
        reset_log_level = true
      end
      catalog = Puppet::Face[:catalog, "0.0"].find
      if reset_log_level
        Puppet[:log_level] = "notice"
      end

      graph = PuppetX::CatalogTranslation.to_mgmt(catalog.to_ral)
      PuppetX::CatalogTranslation.desymbolize(graph)
    end
  end
end
