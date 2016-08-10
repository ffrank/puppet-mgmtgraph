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

  ignore :provider

  ignore :configfiles do |value|
    if value != :keep
      Puppet.warning "#{@resource.ref} is set to #{value} config files, which does not translate."
    end
  end

  ignore :reinstall_on_refresh do |value|
    if value != :false
      Puppet.warning "#{@resource.ref} will reinstall itself when notified, which mgmt does not support."
    end
  end
end
