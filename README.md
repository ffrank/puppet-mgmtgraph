#puppet-mgmtgraph

[![Build Status](https://travis-ci.org/ffrank/puppet-mgmtgraph.svg?branch=master)](https://travis-ci.org/ffrank/puppet-mgmtgraph)

Adds the `:mgmtgraph` face and `puppet mgmtgraph` subcommand to [Puppet](https://github.com/puppetlabs/puppet).
It allows you to compile simple Puppet manifest into a data structure that is
suitable for [mgmt](https://github.com/purpleidea/mgmt/) to consume.

Released under the terms of the Apache 2 License.

Authored by Felix Frank.

## Usage

It is no longer necessary to invoke `puppet mgmtgraph` directly, since it's possible to use `mgmt`'s `--puppet` switch
to load the resulting graph directly.

Still, for testing and debugging, the tool is still useful. It can also make sense to save a translated YAML graph
to a file in order to cache it. After all, building the catalog is usually the most time consuming part when running
`mgmt` from a Puppet manifest.

### Manual invocation

Currently, the most useful invocation of `puppet mgmtgraph` targets single manifests of simple structure

    puppet mgmtgraph --manifest /path/to/my.pp >/tmp/mygraph.yaml

The manifest can use modules from the configured environment, but please note that this likely clashes with current
[limitations](#limitations).

With no manifest specified, `puppet mgmtgraph` will behave like `puppet agent` and receive
the catalog from the configured master, using its agent certificate. (This works courtesy
of the `puppet catalog` face.)

    puppet mgmtgraph >/tmp/mygraph.yaml

A handy shortcut for testing simple manifests is the `--code` parameter

    puppet mgmtgraph --code 'file { "/tmp/test": ensure => present } -> package { "cowsay": ensure => installed }'

Finally, run the graph through [mgmt](https://github.com/purpleidea/mgmt/)

    mgmt run --file /tmp/mygraph.yaml

### Conservative mode

In its default ("optimistic") mode, `puppet mgmtgraph` will emit as many native `mgmt` resources as possible.
This will drop some attribute values to the floor, however. Consider the following simple manifest:

    file { "/tmp/exchange_file": ensure => file, seltype => "tmp_t" }

As long as `mgmt` has no SELinux support, it can create and maintain the file, but will ignore its SEL context.
In a more complex manifest context, this is likely inadequate to prepare the system for the synchronization
of all dependent resources.

In order to make sure that `mgmt` applies such a catalog correctly, it has to resort to the `puppet resource`
workaround that is used for resources that are not supported by `mgmt` at all (see below).
This behavior is now available in the form of the `conservative` mode:

    puppet mgmtgraph --conservative --code 'file { "/tmp/exchange_file": ensure => file, seltype => "tmp_t" }'

The `mgmt` integration has no way of passing this flag. However, eventually this mode will probably become
the default, with an optional `--optimistic` flag to revert to the current default.

## Limitations

Translation of virtual and exported resources is untested. Containment of supported resources
in classes and defined types should work.

The set of supported catalog elements is still quite small:

 * file resources
 * exec resources
 * service resources
 * package resources
 * notify resources

For most of these, `mgmt` does not support all available properties and parameters.
Whenever an attribute is ignored because of that, a warning message is printed during translation.
There might be edge cases were this does not work reliably.

Resources of unsupported types are rendered into `exec` vertices of the form

```yaml
exec:
- name: <type>:title
  cmd: puppet yamlresource <type> 'title' '{ param => value, ... }'
  ifcmd: puppet yamlresource ... --noop | grep -q ^Notice:
```

This means that testing the sync state of such a resource requires `mgmt` to launch a `puppet yamlresource` process.
If that reports a change in `noop` mode, another `puppet yamlresource` is launched to perform the sync.

In [conservative mode](#conservative-mode), this technique is also applied to resources that are generally
translatable, but raise warnings about specific parameters or values.

## Compatibility

Supports Puppet `5.x` and `4.x`.

Supports `mgmt` 0.0.3 and higher (no earlier releases)

## Extending

See the [DSL Guide](DSL.md).

## TODO

* easier DSL (e.g. add a method to get at the namevar)
* support for export and import of resources (if possible)
* enhance performance when delegating resources to Puppet
