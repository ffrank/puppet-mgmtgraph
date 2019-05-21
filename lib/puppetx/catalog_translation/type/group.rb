module PuppetX::CatalogTranslation
  Type.new :group do
    spawn :name do
      @resource.title
    end

    carry :gid

    rename :ensure, :state do |value|
      case value
      when :present
        :exists
      when :absent
        :absent
      else
        translation_failure "cannot translate group ensure:#{value}"
      end
    end

    ignore :allowdupe do |value|
      if value
        translation_failure "uses the allowdupe attribute, which cannot be translated."
      end
    end

    ignore :system do |value|
      if value
        translation_failure "uses the system attribute, which cannot be translated."
      end
    end

    ignore :provider do |value|
      translation_warning "provider (#{value}) is ignored"
    end

    ignore :auth_membership do |value|
      if value
        translation_failure "uses the auth_membership attribute, which cannot be translated"
      end
    end

    ignore :attribute_membership do |value|
      if value != :minimum
        translation_failure "uses the attribute_membership attribute, which cannot be translated"
      end
    end

  end
end
