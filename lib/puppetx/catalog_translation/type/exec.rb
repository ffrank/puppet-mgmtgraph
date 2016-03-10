require 'puppetx/catalog_translation/type'

PuppetX::CatalogTranslation::Type.new :exec do
  spawn :name do
    @resource.title
  end

  spawn :cmd do
    @resource[:name]
  end

  carry :timeout

  spawn(:shell, :watchcmd, :watchshell, :ifshell) { "" }

  rename :onlyif, :ifcmd

  spawn(:state) { :present }

  spawn(:pollint) { 0 }
end
