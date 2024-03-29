require 'puppet/resource/catalog'
require 'puppet/type'
require 'puppet/configurer'
require 'puppetx/catalog_translation/type'

class Puppet::Configurer
  def get_simple_catalog
    report = Puppet::Transaction::Report.new(nil, @environment, nil, nil)
    options = { :report => report }
    if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '6.14.0') != -1
      query_options, facts = get_facts(options)
      prepare_and_retrieve_catalog(nil, facts, options, query_options)
    else
      query_options = get_facts(options)
      versions_with_cached_parameter = %w{5.5.18 5.5.19 5.5.20 5.5.21 5.5.22 6.4.5}
      if Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '6.12.0') != -1 or
          versions_with_cached_parameter.include?(Puppet::PUPPETVERSION)
        prepare_and_retrieve_catalog(nil, options, query_options)
      else
        prepare_and_retrieve_catalog(options, query_options)
      end
    end
  end
end

module PuppetX; end

module PuppetX::CatalogTranslation
  MINPUPPETVERSION='4.0.0'

  @mode = :optimistic
  @pippet = true

  def self.to_mgmt(catalog)
    result = {
      :graph => catalog.name,
      :comment => "generated from puppet catalog for #{catalog.name}",
      :resources => {},
      :edges => [],
    }

    resource_table = {}

    catalog.relationship_graph.vertices.each do |res|
      # initially mark as untranslated
      resource_table[res] = nil
      next unless translator = PuppetX::CatalogTranslation::Type.translation_for(res.type)
      next unless translator.output

      type, data = translator.translate!(res)
      result[:resources][type] ||= []
      result[:resources][type] << data
      # cache the translation result
      resource_table[res] = { :kind => type, :name => data[:name] }
    end

    catalog.relationship_graph.edges.each do |edge|
      from = resource_table[edge.source]
      to = resource_table[edge.target]

      next unless from and to
      # deterministic edge naming is important
      edge_id = "#{edge.source.ref} -> #{edge.target.ref}"
      result[:edges] << { :name => edge_id, :from => from, :to => to }
    end

    desymbolize(result)
  end

  def self.stats(catalog)
    PuppetX::CatalogTranslation::Type.reset_error_log!

    catalog.relationship_graph.vertices.each do |res|
      next unless translator = PuppetX::CatalogTranslation::Type.translation_for(res.type)
      next unless translator.output
      translator.translate!(res)
    end

    PuppetX::CatalogTranslation::Type.dump_error_log
  end

  def self.get_catalog
    # suppress performance message from the compiler
    if Puppet[:log_level] == "notice"
      Puppet[:log_level] = "warning"
      reset_log_level = true
    end
    if Puppet[:manifest].nil?
      configurer = Puppet::Configurer.new
      catalog = configurer.get_simple_catalog
    else
      catalog = Puppet::Face[:catalog, "0.0"].find
    end
    if reset_log_level
      Puppet[:log_level] = "notice"
    end
    if catalog.nil?
      raise Puppet::Error.new("Aborting translation because catalog is not available")
    end
    catalog
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

  def self.set_mode(mode)
    case mode
    when :conservative, :optimistic
      @mode = mode
    else
      raise "cannot set #{self.name} to invalid '#{mode}' mode"
    end
  end

  def self.mode
    return @mode
  end

  def self.disable_pippet
    @pippet = false
  end

  def self.pippet_enabled?
    return @pippet
  end

  def self.assert_puppet_version
    if Gem::Version.new(Puppet.version) < Gem::Version.new(MINPUPPETVERSION)
      raise Puppet::Error.new("The puppet mgmtgraph module requires Puppet 4 or greater, version #{Puppet.version} is not supported.")
    end
  end
end
