require 'puppet/resource/catalog'
require 'puppet/type'
require 'puppetx/catalog_translation/type'

module PuppetX; end

module PuppetX::CatalogTranslation
  def self.to_mgmt(catalog)
    result = {
      :graph => catalog.name,
      :comment => "generated from puppet catalog for #{catalog.name}",
      :resources => {},
      :edges => [],
    }

    catalog.relationship_graph.vertices.each do |res|
      next unless translator = PuppetX::CatalogTranslation::Type.translation_for(res.type)
      next unless translator.output
      result[:resources][translator.output] ||= []
      result[:resources][translator.output] << translator.translate!(res)
    end

    catalog.relationship_graph.edges.each do |edge|
      from = translate_vertex(edge.source)
      to = translate_vertex(edge.target)

      next unless from and to
      # deterministic edge naming is important
      edge_id = "#{edge.source.ref} -> #{edge.target.ref}"
      result[:edges] << { :name => edge_id, :from => from, :to => to }
    end

    desymbolize(result)
  end

  def self.translate_vertex(vertex)
    type = vertex.type
    return nil unless translator = PuppetX::CatalogTranslation::Type.translation_for(type)
    type = translator.output
    return nil unless type
    title = translator.title(vertex)
    return { :kind => type, :name => title }
  end

  def self.desymbolize(it)
    case it
    when Symbol
      it.to_s
    when Array
      it.collect { |x| desymbolize x }
    when Hash
      result = {}
      it.each do |k,v|
        result[desymbolize(k)] = desymbolize v
      end
      result
    else
      it
    end
  end
end
