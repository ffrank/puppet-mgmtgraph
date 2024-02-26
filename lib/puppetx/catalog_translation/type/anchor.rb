PuppetX::CatalogTranslation::Type.new :anchor do
  emit :noop

  spawn :name do
    @resource[:name]
  end
end
