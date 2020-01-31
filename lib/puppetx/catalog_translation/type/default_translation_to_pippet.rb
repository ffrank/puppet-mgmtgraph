PuppetX::CatalogTranslation::Type.new :default_translation_to_pippet do
  emit :pippet

  catch_all

  # this is the name of the pippet resource in the mgmt graph
  spawn :name do
    @resource.type.to_s.capitalize + "[" + @resource[:name] + "]"
  end

  # this is for the Title parameter in the pippet resource
  # (i.e., what gets passed to Puppet as resource title)
  spawn :title do
    @resource.title
  end

  spawn :type do
    @resource.type.to_s
  end

  spawn :params do
    @resource.to_hash.reject { |attr,value|
      [ :name,
        # ignore relational metaparameters, those are handled through the actual
        # edges in the RAL graph
        :before, :require, :notify, :subscribe,
      ].include? attr
    }
  end

  spawn(:pollint) { Puppet[:runinterval] }
end
