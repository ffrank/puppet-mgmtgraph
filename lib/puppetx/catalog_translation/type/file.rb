require 'puppetx/catalog_translation/type'

module PuppetX::CatalogTranslation
  Type.new :file do
    spawn :name do
      @resource.title
    end

    spawn :path do
      @resource[:name]
    end

    rename :ensure, :state do |value|
      case value
      when :present, :file
        :exists
      when :absent
        :absent
      else
        raise "cannot translate file ensure:#{value}"
      end
    end

    carry :content do |content|
      @resource.parameters[:content].actual_content
    end
  end
end
