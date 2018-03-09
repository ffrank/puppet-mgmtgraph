require 'puppet/face'
require 'puppetx/catalog_translation'
require 'puppetx/catalog_translation/type'

Puppet::Face.define(:mgmtgraph, '0.0.1') do
  
  license "Apache 2"
  copyright "Felix Frank", 2016
  author "Felix Frank <felix.frank@alumni.tu-berlin.de>"
  summary "Generate a catalog and generate a mgmt compatible graph from it."

  action :print do
    default
    summary "Print the graph in YAML format"
    option "--conservative" do
      summary "Emit `exec puppet resource` nodes in case of translation limitations"
    end

    when_invoked do |options|
      graph = Puppet::Face[@name, @version].find(:conservative => options[:conservative])
      puts YAML.dump graph
    end
  end

  action :find do
    summary "Return the graph in hash format"
    option "--conservative" do
      summary "Emit `exec puppet resource` nodes in case of translation limitations"
    end
    when_invoked do |options|

      catalog = PuppetX::CatalogTranslation.get_catalog

      if options[:conservative]
	PuppetX::CatalogTranslation.set_mode(:conservative)
      else
	PuppetX::CatalogTranslation.set_mode(:optimistic)
      end

      PuppetX::CatalogTranslation.to_mgmt(catalog.to_ral)
    end
  end

  action :stats do
    summary "Print statistics about translation issues"

    when_invoked do |options|
      catalog = PuppetX::CatalogTranslation.get_catalog
      puts PuppetX::CatalogTranslation.stats(catalog.to_ral)
    end
  end
end
