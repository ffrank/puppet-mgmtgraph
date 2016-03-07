require 'puppet/resource/catalog'
require 'puppet/type'
require 'puppet/type/stage'
require 'puppet/type/component'

module PuppetX; end

module PuppetX::CatalogTranslation
  def self.to_mgmt(catalog)
    result = {
      :graph => catalog.name,
      :comment => "generated from puppet catalog for #{catalog.name}",
    }
    result[:types] = {}
    edge_counter = 1

    catalog.resources.select { |res|
      case res
      when Puppet::Type::Component
        false
      when Puppet::Type::Stage
        false
      when Puppet::Type
        true
      else
        false
      end
    }.map(&:to_resource).map(&:to_data_hash).each do |resource_hash|
      next unless node = mgmt_type(resource_hash)
      result[:types][node[:type]] ||= []
      result[:types][node[:type]] << node[:content]
    end

    catalog.relationship_graph.edges.map(&:to_data_hash).each do |edge|
      from = parse_ref(edge["source"])
      to = parse_ref(edge["target"])

      next unless from and to
      next_edge = "e#{edge_counter += 1}"

      result[:edges] ||= []
      result[:edges] << { :name => next_edge, :from => from, :to => to }
    end

    result
  end

  def self.mgmt_type(resource)
    result = {}
    resource["parameters"] ||= {} # resource w/o parameters
    case resource["type"]
    when 'File'
      result[:type] = :file
      result[:content] = {
        :name => resource["title"],
        :path => resource["parameters"][:path] || resource["title"],
      }
      if resource["parameters"][:ensure]
        result[:content][:state] = case resource["parameters"][:ensure]
          when :present, :file
            :exists
          when :absent
            :absent
        end
      end
      if resource["parameters"]["content"]
        result[:content][:content] = resource["parameters"][:content]
      end
      result
    when 'Exec'
      result[:type] = :exec
      result[:content] = {
        :name => resource["title"],
        :cmd  => resource["parameters"][:command] || resource["title"],
        :shell => resource["parameters"][:shell] || "",
        :timeout => resource["parameters"][:timeout] || 0,
        :watchcmd => "",
        :watchshell => "",
        :ifcmd => resource["parameters"][:onlyif] || "",
        :ifshell => "",
        :pollint => 0,
        :state => :present
      }
      result
    end
  end

  # From File["foo"] to { type => file, name => foo }
  def self.parse_ref(ref)
    if ! ref.match /^(.*)\[(.*)\]$/
      raise "unexpected reference format '#{ref}'"
    end
    type = $1.downcase
    title = $2
    return nil unless [ 'file', 'exec', 'service' ].include? type
    return { :type => type, :name => title }
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
