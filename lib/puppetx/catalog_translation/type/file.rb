module PuppetX::CatalogTranslation
  Type.new :file do
    spawn :name do
      @resource.title
    end

    spawn :path do
      if @resource[:ensure] == :directory
        @resource[:name] + "/"
      else
        @resource[:name]
      end
    end

    rename :ensure, :state do |value|
      case value
      when :present, :file, :directory
        :exists
      when :absent
        :absent
      else
        raise "cannot translate file ensure:#{value}"
      end
    end

    # This is a minor hack: the content parameter could actually
    # be carried over to mgmt. However, for directories, Puppet does
    # not use content and relies on 'source' instead. The easiest
    # way to consolidate these scenarios is this spawn.
    spawn :content do
      if @resource[:ensure] == :directory && !@resource[:source].nil?
        source = @resource[:source][0].sub(/^file:/, '')
        if @resource[:source].count > 1
          Puppet.err "#{@resource.ref} uses multiple sources - this will not be translated"
          ''
        elsif source =~ /^puppet:/
          Puppet.err "#{@resource.ref} uses a puppet fileserver URL source - this will not be translated"
          ''
        else
          source
        end
      elsif @resource.parameters[:content]
        @resource.parameters[:content].actual_content
      end
    end
  end
end
