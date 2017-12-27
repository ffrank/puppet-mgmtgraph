PuppetX::CatalogTranslation::Type.new :augeas do

  spawn :name do
    @resource.title
  end

  carry :lens

  spawn :file do
    if @resource[:incl]
      @resource[:incl]
    else
      translation_failure "does not use the 'incl' parameter, which mgmt needs"
      nil
    end
  end
  ignore :incl

  rename :changes, :sets do |value|
    result = value.map do |change|
      unless change =~ /^set /
        translation_failure "has the change '#{change}', but only 'set' is supported. skipping..."
        {}
      else
        fields = change.split(" ",3)
        { 'path' => fields[1], 'value' => fields[2] }
      end
    end
    result.reject! { |x| x.empty? }

    if result.empty?
      translation_warning "dropped all changes due to lack of support"
    end

    result
  end

  ignore :context do |value|
    if not @resource[:incl] && value.empty?
      nil
    elsif value != "/files#{ @resource[:incl] }"
      translation_failure "overrides the 'context' parameter (#{value}), which does not translate"
    end
  end

  ignore :force do |value|
    if value
      translation_failure "uses the unsupported 'force' parameter"
    end
  end

  ignore :load_path do |value|
    if ! value.empty?
      translation_warning "uses the 'load_path' parameter, which is ignored, so the lens might not be found"
    end
  end

  ignore :onlyif do |value|
    if ! value.empty?
      translation_failure "uses the unsupported 'onlyif' parameter"
    end
  end

  ignore :provider, :returns

  ignore :root do |value|
    if value != '/'
      translation_failure "uses the unsupported 'root' parameter"
    end
  end

  ignore :show_diff do |value|
    if ! value
      translation_warning "uses the unsupported 'show_diff' parameter"
    end
  end

  ignore :type_check do |value|
    if value != false && value != :false
      translation_warning "uses the unsupported 'type_check' parameter"
    end
  end

  # mgmt (currently) has no notion of scope
  ignore :withpath
end
