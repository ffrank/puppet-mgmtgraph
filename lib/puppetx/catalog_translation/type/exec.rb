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

  ignore :command, :provider, :logoutput, :try_sleep

  ignore :returns do |value|
    if value != %w{0}
      Puppet.err "#{@resource.ref} expects return code(s) other than 0, which mgmt does not support."
    end
  end

  ignore :tries do |value|
    if value > 1
      Puppet.err "#{@resource.ref} has #{value} tries, which mgmt will not use."
    end
  end
end
