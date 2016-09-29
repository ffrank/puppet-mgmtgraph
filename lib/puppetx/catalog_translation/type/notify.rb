PuppetX::CatalogTranslation::Type.new :notify do
  emit :msg

  spawn :name do
    @resource.title
  end

  spawn :body do
    @resource[:name]
  end

  rename(:loglevel, :priority) do |value|
    if value == 'verbose'
      'Notice'
    else
      value.capitalize
    end
  end

  # mgmt (currently) has no notion of scope
  ignore :withpath
end
