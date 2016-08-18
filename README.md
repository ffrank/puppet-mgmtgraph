#puppet-mgmtgraph

[![Build Status](https://travis-ci.org/ffrank/puppet-mgmtgraph.png)](https://travis-ci.org/ffrank/puppet-mgmtgraph)

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

## Limitations

Translation of virtual and exported resources is untested. Containment of supported resources
in classes and defined types should work.

The set of supported catalog elements is still quite small:

 * file resources
 * exec resources
 * service resources
 * package resources

For most of these, `mgmt` does not support all available properties and parameters.
Whenever an attribute is ignored because of that, a warning message is printed during translation.
There might be edge cases were this does not work reliably.

Resources of unsupported types are rendered into `exec` vertices of the form

```yaml
exec:
- name: <type>:title
  cmd: puppet yamlresource <type> 'title' '{ param => value, ... }'
  watchcmd: puppet yamlresource ... --noop | grep -q ^Notice:
```

This means that testing the sync state of such a resource requires `mgmt` to launch a `puppet yamlresource` process.
If that reports a change in `noop` mode, another `puppet yamlresource` is launched to perform the sync.

## Compatibility

Supports Puppet `3.x` and `4.x`.

Supports `mgmt` 0.0.3 (no earlier releases)

## TODO

* easier DSL (e.g. add a method to get at the namevar)
* support for export and import of resources (if possible)
* enhance performance when delegating resources to Puppet
