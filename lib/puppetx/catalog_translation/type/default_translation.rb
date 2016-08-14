PuppetX::CatalogTranslation::Type.new :default_translation do
  emit :exec

  override_title

  catch_all

  spawn :name do
    @resource.type.to_s.capitalize + ":" + @resource[:name]
  end

  def command(resource)
    r_type = @resource.type.to_s
    r_title = @resource[:name]
    r_params = @resource.to_hash.reject { |attr,value|
      attr == :name
    }
    "puppet yamlresource #{r_type} '#{r_title}' '#{Psych.to_json(r_params).chomp}'"
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
  spawn(:ifcmd) { "#{command(@resource)} --noop --color=false | grep -q ^Notice:" }

  spawn(:state) { :present }

  spawn(:pollint) { 0 }
end
