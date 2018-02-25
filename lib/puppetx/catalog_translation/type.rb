module PuppetX
module CatalogTranslation
  class Type
    attr_reader :name, :output

    @instances = {}

    # when nil, just display errors. Otherwise, assume is a hash of 'message(string) => count(int)'
    @messages = nil

    def initialize(name,&block)
      @name = name
      @output = name # can be overridden from DSL
      @translations = {}
      @custom_title = false
      @catch_all = false
      instance_eval(&block)

      # ignore loglevel per default (it's even set for whits)
      if !@translations[:loglevel]
        ignore :loglevel
      end

      # ignore relational metaparameters, those are handled through the actual
      # edges in the RAL graph
      ignore :before, :require, :notify, :subscribe

      self.class.register self
    end

    def translate!(resource)
      result = {}
      # temporarily set @resource to the parameter
      # for use by the blocks
      @resource = resource
      # initially, mark this translation as clean
      mark_as_clean

      seen = {}

      @translations.each do |attr,translation|
        # cache for reference below
        seen[attr] = true

        # dropped attribute is used in the catalog
        if translation[:ignore] && resource.parameters[attr]
          translation[:block].call(resource[attr]) if translation[:block]
          next
        end

        # transform attribute name (onlyif -> ifcmd)
        title = translation[:alias] || attr

        # spawn additional attributes (watchcmd...)
        if translation[:spawned]
          result[title] = translation[:block].call
          next
        end

        # non-spawned attributes must exist in the source catalog
        next if !resource.parameters[attr]

        # actual translation
        result[title] = if translation.has_key?(:block)
          translation[:block].call(resource[attr])
        else
          resource[attr]
        end
      end

      if !@catch_all
        # unmatched resource attributes get raised as an error
        # translators should explicitly ignore them to avoid this
        resource.parameters.keys.each do |attr|
          next if seen[attr]
          translation_failure "cannot translate attribute '#{attr} => #{resource[attr].inspect}', attribute is ignored"
        end

        # if a regular (not the catch-all) translation is unclean,
        # the user might wish to defer to the catch-all
        if !@clean_translation && PuppetX::CatalogTranslation.mode == :conservative
          Puppet.warning("emitting a `exec puppet resource` node for #{resource_description} because of the errors above")
          @resource = nil
          return PuppetX::CatalogTranslation::Type.translation_for(:default_translation).translate!(resource)
        end
      end

      @resource = nil
      return @output, result
    end

    def self.translation_for(type)
      unless @instances.has_key? :default_translation
        load_translator(:default_translation)
      end
      unless @instances.has_key? type
        load_translator(type)
      end
      @instances[type] || @instances[:default_translation]
    end

    def title(resource)
      if @custom_title
        @resource = resource
        result = @translations[:name][:block].call
        @resource = nil
        result
      else
        resource[:name]
      end
    end

    # For testing only: unloads all translators.
    def self.clear
      @instances = {}
      @translations = {}
    end

    def self.reset_error_log!
      @messages = {}
    end

    def self.disable_error_log!
      @messages = nil
    end

    def self.dump_error_log
      list = @messages.keys.sort { |a,b| @messages[b] <=> @messages[a] }
      result = ''
      list.each do |message|
        result += sprintf("%5ix %s\n", @messages[message], message)
      end
      result
    end

    private

    def self.register(instance)
      @instances[instance.name] = instance
    end

    def self.loader
      @loader ||= Puppet::Util::Autoload.new(self, "puppetx/catalog_translation/type")
    end

    def self.load_translator(type)
      loader.load(type)
    end

    def self.log_error(message)
      @messages[message] ||= 0
      @messages[message] += 1
    end

    def self.consolidating?
      return false if @messages.nil?
      # TODO: make it possible to also collect warnings
      :err
    end

    # below are DSL methods

    def carry(*attributes,&block)
      attributes.each do |attribute|
        @translations[attribute] = { :title => attribute, }
        if block_given?
          @translations[attribute][:block] = block
        end
      end
    end

    def rename(attribute,newname,&block)
      if block_given?
        carry(attribute) { |x| block.call(x) }
      else
        carry attribute
      end
      @translations[attribute][:alias] = newname
    end

    def spawn(*attributes,&block)
      attributes.each do |attribute|
        carry(attribute) { yield }
        @translations[attribute][:spawned] = true
      end
    end

    def ignore(*attributes, &block)
      attributes.each do |attribute|
        if block_given?
          carry(attribute) { |x| block.call(x) }
        else
          carry attribute
        end
        @translations[attribute][:ignore] = true
      end
    end

    def emit(output)
      @output = output
    end

    def override_title
      @custom_title = true
    end

    def catch_all
      @catch_all = true
    end

    def translation_warning(message)
      if PuppetX::CatalogTranslation.mode == :conservative
        mark_as_unclean
      end
      unsupported message, :warning
    end

    def translation_failure(message)
      # a failure should always lead to a handed off resource
      mark_as_unclean
      unsupported message, :err
    end

    def resource_description
      if @resource
        @resource.ref
      else
        '[no resource]'
      end
    end

    def generic_description
      resource_description.sub(/\[.*\]/, '[...]')
    end

    def unsupported(message, level = :warning)
      if self.class.consolidating?
        log_resource_error(message, level)
        return
      end

      case level
      when :warning, :err
        Puppet.send(level, "#{resource_description} #{message}")
      else
        raise "invalid message level '#{level}' in #{self.class.name}#unsupported (while translating #{@resource.inspect if @resource})"
      end
    end

    def log_resource_error(message, level)
      return if level != :err and self.class.consolidating? == :err
      self.class.log_error("#{generic_description} #{message}")
    end

    def mark_as_unclean
      @clean_translation = false
    end

    def mark_as_clean
      @clean_translation = true
    end
  end
end
end
