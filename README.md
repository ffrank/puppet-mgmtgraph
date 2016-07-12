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

The set of supported catalog elements is still quite small:

 * file resources
 * exec resources
 * service resources
 * package resources

Resources of other types are silently dropped.

Translation of virtual and exported resources is untested. Containment of supported resources
in classes and defined types should work.

Basically, a supported manifest can currently look like the following:

```puppet
    class x { file { 'd': } }

    define thing($file=$name) { file { "/tmp/$file": ... } }

    include x

    package { 'x': ... }
    ->
    file { 'a': ... }

    thing { 'f': file => 'f-thing', }
    ->
    Class['x']
    ->
    exec { 'b': ... }
    ->
    service { 'c': require => File['a'], ... }
```

## Compatibility

Supports Puppet `3.x` and `4.x`.

Supports `mgmt` 0.0.3 (no earlier releases)

## TODO

* more flexibility in the DSL
* easier DSL (e.g. add a method to get at the namevar)
* general fallback support using `puppet resource` (a.k.a. the Daenny hack)
* support for export and import of resources (if possible)
