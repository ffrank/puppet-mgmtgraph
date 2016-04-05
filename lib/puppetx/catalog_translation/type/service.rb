PuppetX::CatalogTranslation::Type.new :service do
  spawn :name do
    @resource[:name]
  end

  rename :ensure, :state do |value|
    case value
    when :running, true, :true
      :running
    else
      :stopped
    end
  end

  rename :enable, :startup do |value|
    if value == true || value == :true
      :enabled
    else
      :disabled
    end
  end
end
