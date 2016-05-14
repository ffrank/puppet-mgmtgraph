PuppetX::CatalogTranslation::Type.new :exec do
  spawn :name do
    @resource.title
  end

  spawn :cmd do
    @resource[:name]
  end

  carry :timeout

  spawn(:shell, :watchshell, :ifshell) { "/bin/bash" }

  spawn(:watchcmd) { "while : ; do echo \"puppet run interval passed\" ; /bin/sleep #{Puppet[:runinterval]} ; done" }

  rename :onlyif, :ifcmd

  spawn(:state) { :present }

  spawn(:pollint) { 0 }
end
