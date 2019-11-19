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
        translation_failure "cannot translate file ensure:#{value}"
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
          translation_failure "uses multiple sources - this will not be translated"
          ''
        elsif source =~ /^puppet:/
          translation_failure "uses a puppet fileserver URL source - this will not be translated"
          ''
        else
          source.gsub(/\/+/, '/')
        end
      elsif @resource.parameters[:content]
        @resource.parameters[:content].actual_content
      end
    end

    # this is consumed in the spawn :content block above
    ignore :source

    ignore :validate_replacement, :provider, :sourceselect, :show_diff, :checksum

    ignore :validate_cmd do
      translation_warning "has a validate_cmd, which does not translate to mgmt. There will be no validation!"
    end

    ignore :purge do |value|
      if value
        translation_failure "uses the purge attribute, which cannot be translated. Unmanaged content will be ignored."
      end
    end

    ignore :backup do |value|
      case value
      when false, nil, 'puppet'
        nil
      when /^\./
        translation_warning "uses local backups with a suffix, which mgmt does not support. There will be no backup copies!", value
      else
        translation_warning "uses a file bucket, which mgmt cannot do. There will be no backup copies!", value
      end
    end

    ignore :replace do |value|
      if !value
        translation_failure "sets replace => false, which is not available in mgmt."
      end
    end

    ignore :links do |value|
      if value != :manage
        translation_failure "is configured to follow symlinks, which does not translate."
      end
    end

    ignore :source_permissions do |value|
      if value != :ignore
        translation_failure "does not ignore source permissions, which does not translate."
      end
    end

    ignore :selinux_ignore_defaults do |value|
      if !value
        translation_warning "respects selinux defaults, which will not happen from mgmt."
      end
    end

  end
end
