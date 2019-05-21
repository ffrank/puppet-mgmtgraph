module PuppetX::CatalogTranslation
  Type.new :mount do
    spawn :name do
      @resource.title
    end

    carry :device

    rename :ensure, :state do |value|
      case value
      when :present, :defined, :mounted
        :exists
      when :absent, :unmounted
        :absent
      else
        translation_failure "cannot translate mount ensure:#{value}"
      end
    end

    rename :fstype, :type

    rename :dump, :freq

    rename :pass, :passno

    # options needs to be a proper hash for mgmt, rather than the string in puppet
    carry :options do |value|
      result = {}
      value.split(/,/).each do |entry|
        ( option, value ) = entry.split(/=/)
        if !value.nil?
          result[option] = value
        else
          result[entry] = ""
        end
      end
      result
    end

    ignore :provider do |value|
      if value != :parsed
        translation_failure "uses non-default provider #{value} which does not translate"
      end
    end

    ignore :target do |value|
      if value != "/etc/fstab"
        translation_failure "uses non-standard target #{value}, translation works for /etc/fstab only"
      end
    end

    ignore :remounts do |value|
      if value != :true
        translation_warning "disables remounts, which cannot be translated. This will be ignored."
      end
    end

  end
end
