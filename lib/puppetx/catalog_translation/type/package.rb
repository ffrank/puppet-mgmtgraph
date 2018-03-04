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
      translation_failure "uses an ensure value that currently cannot be translated for mgmt (defaulting to 'installed')", value
      :installed
    end
  end

  ignore :provider

  ignore :allow_virtual do |value|
    if !value or value == :false
      translation_warning "does not allow virtual package names, which mgmt does not know about"
    end
  end

  ignore :configfiles do |value|
    if value != :keep
      translation_warning "is set a non-default value, which does not translate.", value
    end
  end

  ignore :reinstall_on_refresh do |value|
    if value != :false
      translation_warning "will reinstall itself when notified, which mgmt does not support."
    end
  end
end
