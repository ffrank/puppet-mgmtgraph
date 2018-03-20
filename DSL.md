# mgmtgraph DSL

Rules for translating Puppet resources are defined in a Ruby DSL.
This document describes this language and serves as a reference.

## Basics

For any given Puppet resource type (such as `file`, `service`, and so forth),
a specific set of rules can be created.

This is always done with a call to `PuppetX::CatalogTranslation::Type.new`.
The resulting rule-set is commonly called a `translator`.
Rule DSL code is given to this method as a block. You can find examples in the
[type subdirectory](https://github.com/ffrank/puppet-mgmtgraph/tree/master/lib/puppetx/catalog_translation/type)
of the source code.

DSL code can use the `@resource` member variable. During translation,
it holds the original Puppet resource that is being translated. This is
an instance of (a subclass of) `Puppet::Type`.

Puppet tries to auto-load translators from the subtree
`puppetx/catalog_translation/type` in any library location, such as modules.

"Core" translators are defined right in this module, and it's quite possible
that all translatable types will be maintained here indefinitely.

## Translator rules

The translation approach works as follows:

1. The translator engine loads the translator for the given Puppet resource type.

2. Each rule from the translator is applied in turn.
   The rules "consume" attributes from the input resource
   and add parameters to the output resource.

3. Unconsumed attributes lead to a `translation failure` (see Reporting below).

These are the available types of rules:

### `carry` rules

The most simple kind of rule. Accepts one or more attribute names (as Ruby symbols).
The named attributes are *carried* over to `mgmt` as they are.

    carry :mode
    carry :owner, :group

Optionally, a block can apply a transformation to the value.

    carry :myattr do |value|
      case value
      when true, false
        value
      when nil
        false
      else
        translation_failure "uses an unsupported value for myattr.", value
      end
    end

### `rename` rules

A rename rule takes the name of a Puppet attribute and the name of the corresponding
parameter in `mgmt` (both as Ruby symbols).

    rename :onlyif, :ifcmd

Optionally, a block can apply a transformation to the value.

    rename :ensure, :state do |value|
      case value
      when :present, :file, :directory
        :exists
      when :absent
        :absent
      else
        translation_failure "uses an ensure value that cannot be translated.", value
      end
    end

### `spawn` rules

A spawn rule generates an `mgmt` parameter that does not directly correlate to
a Puppet attribute (i.e., cannot be handled by a `carry` or `rename` rule).

Such rules usually base their output on the `@resource` member variable.
(Please note that *all* types of rules can make use of `@resource`.)

    spawn :content do
      if @resource[:ensure] == :directory && !@resource[:source].nil?
        source
      elsif @resource.parameters[:content]
        @resource.parameters[:content].actual_content
      end
    end

The above example is basically a `carry` hybrid. It cannot use `carry`, however.
That's because resources such as the following have no `content` attribute:

    file { "/tmp/archives": source => "/var/lib/archives-0.1.1" }

A `carry` rule can not rename the `source` parameter to `content`, so a `spawn`
rule does the right thing, depending on the input.

A special idiomatic `spawn` rule works as follows:

    spawn :name do
      @resource.title
    end

All `mgmt` resources need names, and usually, we just use Puppet's resource title.
This **cannot** be expressed as a `rename` rule, because `@resource.title` is a
method call on the Puppet resource object, not an access to an attribute. The title
is special, and not part of `@resource.parameters`.

(Note: The above rule can only be used safely for `mgmt` resource kinds that don't
derive meaning from the `name` parameter. Resource kinds such as `pkg` use a different
idiom, see the section on "Namevar" below.)

### `ignore` rules

A special type of rule is `ignore`. It has no effect on the output resource for `mgmt`.
It just consumes the named attribute from the input resource. This is important,
because unconsumed attributes are considered translation failures (see Reporting below).

The name of the input resource attribute is given as a Ruby symbol.

    ignore :hasstatus

    ignore :provider

An optional block can be used to issue custom warning or failure messages.

    ignore :purge do |value|
      if value
        translation_warning "uses the purge attribute, which cannot be translated. Unmanaged content will be ignored."
      end
    end

### `emit` rules

This is another special type of rule. There can be at most one `emit` rule
in a translator. It specifies the `kind` of the output resource for `mgmt`.
If no such rule is present, the `kind` is equal to the type of the input resource
from Puppet (e.g. `file`, `exec`).

    emit :svc

    emit :pkg

## Namevar in Puppet

Some resources in Puppet conflate a special parameter with the respective resource titles.
For example, the `title` of a `file` resource will stand in for its `path` parameter.
The following two resources are equivalent:

    file { "the-config": path => "/etc/my_config_file" }

    file { "/etc/my_config_file": }

The only difference is that the former resource has an alias name, "the-config".

This equivalence stems from the fact that `path` is *namevar* for the `file` type.
Other examples are the `command` parameter for the `exec` type, or the `message`
parameter of `notify`.

Other resource types, such as `package` or `service`, have no such special namevar,
and have a `name` parameter instead, which is not commonly used in manifests.

Translating the value of such a namevar requires another translator DSL idiom,
because some input resources will use it explicitly, but not all. A `rename`
or `carry` rule will not work reliably here, because it will only fire for
input resources that specify the namevar as a parameter.

Here is what to do instead:

    spawn :cmd do
      resource[:name]
    end

This retrieves the input resource name, regardless of how it is specified (by
title or parameter). Most translators need the following rule:

    spawn :name do
      resource[:name]
    end

## Reporting

To give feedback to the user, rule blocks can use two DSL methods:

1.  `translation_warning` to indicate that some detail of the input resource
    will not be carried to `mgmt` properly. However, the managed system will
    still be brought into the desired state.
    
    Examples for this include the `backup` parameter of the `file` resource, or its
    `validate_cmd` parameter. Their behavior cannot be mimicked by `mgmt`, but this is
    not critical to the correct behavior of the managed system.
    
        translation_warning "uses local backups, which mgmt will not create."
    
    The translation engine raises the message on the Puppet `warning` level.

2.  `translation_failure` is for indicating translation issues that will
    lead to insufficient management by `mgmt`.

    Examples include the Puppet `file`'s `replace` parameter, or `ensure`
    values in `package` resources that describe the desired package
    version.
    
        translation_failure "uses a non-standard ensure value, which currently cannot be translated for mgmt (defaulting to 'installed')", value

    The message will be raised on Puppet's `err` level.
    
    Note that a `translation_failure` does not imply the immediate
    termination of the ongoing catalog translation. This decision is
    up to the translator engine. (See "Conservative Mode" in the
    user documentation.)

### Reporting best practices

In the output, the engine will prepend your message with the resource
description, e.g. `File[/etc/ntp.conf]`. The message should form
a sentence (sans subject) in present tense, and start in lower
case (see examples above).

The message should not be concatenated from any variable parts, such
as the value of a parameter. This makes it impossible to consolidate
messages in statistics mode. Use the optional second parameter of
the `translation_failure` and `translation_warning` methods instead:

    # RIGHT use:
    translation_failure "cannot take this value in mgmt.", value
    # WRONG use:
    translation_failure "cannot take the value '#{value}' in mgmt."
