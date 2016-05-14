PuppetX::CatalogTranslation::Type.new :package do
  emit :pkg

  spawn :name do
    @resource[:name]
  end

  rename :ensure, :state do |value|
    case value
    when :installed, :present
      :installed
    when :purged, :absent
      :uninstalled
    else
      Puppet.err("#{@resource.ref} uses ensure => #{value} which currently cannot be translated for mgmt (defaulting to 'installed')")
      :installed
    end
  end
end
