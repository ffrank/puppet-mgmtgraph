PuppetX::CatalogTranslation::Type.new :ec2_instance do
  
  emit :"aws:ec2"

  spawn :name do
    @resource.title
  end

  carry :region

  rename :user_data, :userdata

  rename :ensure, :state

  rename :image_id, :imageid

  rename :instance_type, :type

  ignore :monitoring do |value|
    if value and value != :false
      translation_failure "uses the unsupported 'monitoring' parameter"
    end
  end

  ignore :tenancy do |value|
    if value != :default
      translation_failure "uses the unsupported 'tenancy' parameter"
    end
  end

  ignore :ebs_optimized do |value|
    if value and value != :false
      translation_failure "uses the unsupported 'ebs_optimized' parameter"
    end
  end

  ignore :associate_public_ip_address do |value|
    if value and value != :false
      translation_failure "uses the unsupported 'associate_public_ip_address' parameter"
    end
  end

  ignore :instance_initiated_shutdown_behavior do |value|
    if value != :stop
      translation_failure "uses the unsupported 'instance_initiated_shutdown_behavior' parameter"
    end
  end
end
