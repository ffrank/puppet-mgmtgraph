module PuppetX::CatalogTranslation
  Type.new :file do
    spawn :name do
      @resource.title
    end

    carry :owner

    carry :group

    carry :mode

    carry :recurse

    carry :force

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
          unsupported "#{@resource.ref} uses multiple sources - this will not be translated", :err
          ''
        elsif source =~ /^puppet:/
          unsupported "#{@resource.ref} uses a puppet fileserver URL source - this will not be translated", :err
          ''
        else
          source
        end
      elsif @resource.parameters[:content]
        @resource.parameters[:content].actual_content
      end
    end

    ignore :validate_replacement, :provider, :sourceselect, :show_diff, :checksum

    ignore :validate_cmd do
      unsupported "#{@resource.ref} has a validate_cmd, which does not translate to mgmt. There will be no validation!"
    end

    ignore :purge do |value|
      if value
        unsupported "#{@resource.ref} uses the purge attribute, which cannot be translated. Unmanaged content will be ignored."
      end
    end

    ignore :backup do |value|
      case value
      when false, nil
        nil
      when /^\./
        unsupported "#{@resource.ref} uses local backups with the #{value} suffix, which mgmt does not support. There will be no backup copies!"
      else
        unsupported "#{@resource.ref} uses the '#{value}' file bucket, which mgmt cannot do. There will be no backup copies!"
      end
    end

    ignore :replace do |value|
      if !value
        unsupported "#{@resource.ref} sets replace => false, which is not available in mgmt. Existing file will be overwritten!"
      end
    end

    ignore :links do |value|
      if value != :manage
        unsupported "#{@resource.ref} is configured to follow symlinks, which does not translate."
      end
    end

    ignore :source_permissions do |value|
      if value != :ignore
        unsupported "#{@resource.ref} does not ignore source permissions, which does not translate."
      end
    end

    ignore :selinux_ignore_defaults do |value|
      if !value
        unsupported "#{@resource.ref} respects selinux defaults, which will not happen from mgmt."
      end
    end

  end
end
