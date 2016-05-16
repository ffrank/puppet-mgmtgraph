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

    catalog.resources.each do |res|
      next unless translator = PuppetX::CatalogTranslation::Type.translation_for(res.type)
      result[:resources][translator.output] ||= []
      result[:resources][translator.output] << translator.translate!(res)
    end

    catalog.relationship_graph.edges.map(&:to_data_hash).each do |edge|
      from = parse_ref(edge["source"])
      to = parse_ref(edge["target"])

      next unless from and to
      # deterministic edge naming is important
      edge_id = "#{edge["source"]} -> #{edge["target"]}"
      result[:edges] << { :name => edge_id, :from => from, :to => to }
    end

    desymbolize(result)
  end

  # From File["foo"] to { type => file, name => foo }
  def self.parse_ref(ref)
    if ! ref.match /^(.*)\[(.*)\]$/
      raise "unexpected reference format '#{ref}'"
    end
    type = $1.downcase
    title = $2
    return nil unless translator = PuppetX::CatalogTranslation::Type.translation_for(type.intern)
    type = translator.output
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
