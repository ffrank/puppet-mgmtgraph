PuppetX::CatalogTranslation::Type.new :whit do
  emit :noop

  spawn :name do
    @resource[:name]
  end
end
