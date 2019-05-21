module PuppetX::CatalogTranslation
  Type.new :user do
    spawn :name do
      @resource.title
    end

    carry :uid

    carry :groups do |value|
      [ value.split(',') ].flatten
    end

    rename :ensure, :state do |value|
      case value
      when :present
        :exists
      when :absent
        :absent
      else
        translation_failure "cannot translate user ensure:#{value}"
      end
    end

    rename :home, :homedir

    rename :allowdupe, :allowduplicateuid

    spawn :gid do
      if @resource[:gid].is_a? Integer
        @resource[:gid]
      end
    end

    spawn :group do
      if @resource[:gid] =~ /[a-z]/
        @resource[:gid]
      end
    end

    ignore :comment do |value|
      translation_warning "comments are not supported by mgmt and will be ignored"
    end

    ignore :provider do |value|
      translation_warning "provider (#{value}) is ignored"
    end

    [ :membership, :role_membership, :auth_membership, :profile_membership, :key_membership, :attribute_membership ].each do |membership|
      ignore membership do |value|
        if value != :minimum
          translation_failure "the #{membership.to_s} parameter is not supported"
        end
      end
    end

    ignore :managehome do |value|
      if value
        translation_failure "the managehome parameter is not supported"
      end
    end

    ignore :purge_ssh_keys do |value|
      if value and !value.empty?
        translation_failure "the purge_ssh_keys parameter is not supported"
      end
    end

  end
end
