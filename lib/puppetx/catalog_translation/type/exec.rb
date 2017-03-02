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
      translation_failure "expects return code(s) other than 0, which mgmt does not support."
    end
  end

  # TODO: perhaps spawn a retry metaparameter?
  ignore :tries do |value|
    if value > 1
      translation_warning "has #{value} tries, which is not translated to mgmt."
    end
  end
end
