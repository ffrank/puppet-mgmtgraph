PuppetX::CatalogTranslation::Type.new :default_translation do
  emit :exec

  override_title

  spawn :name do
    @resource.type.to_s.capitalize + ":" + @resource[:name]
  end

  def command(resource)
    r_type = @resource.type.to_s
    r_title = @resource[:name]
    r_params = @resource.parameters_with_value.reject { |param|
      param.isnamevar?
    }.map { |param|
      "#{param.name.to_s}='#{param.value.to_s}'"
    }.join(" ")
    "puppet resource #{r_type} '#{r_title}' #{r_params}"
  end

  spawn :cmd do
    command(@resource)
  end

  spawn(:timeout) { 30 }

  spawn(:shell, :watchshell, :ifshell) { "/bin/bash" }

  spawn(:watchcmd) { "while : ; do echo \"puppet run interval passed\" ; /bin/sleep #{Puppet[:runinterval]} ; done" }

  # to determine sync state, do a noop run and look for a line like this:
  # Notice: /File[/tmp/prtest]/ensure: current_value file, should be absent (noop)
  # XXX this is painful, launches puppet twice for unsynced vertices
  spawn(:ifcmd) { "#{command(@resource)} --noop | grep -q ^Notice:" }

  spawn(:state) { :present }

  spawn(:pollint) { 0 }
end
