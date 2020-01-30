PuppetX::CatalogTranslation::Type.new :default_translation do
  emit :exec

  catch_all

  spawn :name do
    @resource.type.to_s.capitalize + ":" + @resource[:name]
  end

  def command(resource)
    r_type = @resource.type.to_s
    r_title = @resource[:name]
    r_params = @resource.to_hash.reject { |attr,value|
      [ :name,
        # ignore relational metaparameters, those are handled through the actual
        # edges in the RAL graph
        :before, :require, :notify, :subscribe,
      ].include? attr
    }
    "puppet yamlresource #{r_type} '#{r_title}' '#{Psych.to_json(r_params).chomp}'"
  end

  spawn :cmd do
    command(@resource)
  end

  spawn(:timeout) { 30 }

  spawn(:shell, :ifshell) { "/bin/bash" }

  # to determine sync state, do a noop run and look for a line like this:
  # Notice: /File[/tmp/prtest]/ensure: current_value file, should be absent (noop)
  # XXX this is painful, launches puppet twice for unsynced vertices
  spawn(:ifcmd) { "#{command(@resource)} --noop --color=false | grep -q ^Notice:" }

  spawn(:state) { :present }

  spawn(:pollint) { Puppet[:runinterval] }
end
