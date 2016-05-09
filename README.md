#puppet-mgmtgraph

[![Build Status](https://travis-ci.org/ffrank/puppet-mgmtgraph.png)](https://travis-ci.org/ffrank/puppet-mgmtgraph)

Adds the `:mgmtgraph` face and `puppet mgmtgraph` subcommand to [Puppet](https://github.com/puppetlabs/puppet).
It allows you to compile simple Puppet manifest into a data structure that is
suitable for [mgmt](https://github.com/purpleidea/mgmt/) to consume.

Released under the terms of the Apache 2 License.

Authored by Felix Frank.

## Usage

Currently, the most useful invocation of `puppet mgmtgraph` targets single manifests of simple structure

    puppet mgmtgraph --manifest /path/to/my.pp >/tmp/mygraph.yaml

The manifest can use modules from the configured environment, but please note that this likely clashes with current
[limitations](#limitations).

With no manifest specified, `puppet mgmtgraph` will behave like `puppet agent` and receive
the catalog from the configured master, using its agent certificate. (This works courtesy
of the `puppet catalog` face.)

    puppet mgmtgraph >/tmp/mygraph.yaml

Finally, run the graph through [mgmt](https://github.com/purpleidea/mgmt/)

    mgmt run --file /tmp/mygraph.yaml

## Limitations

The set of supported catalog elements is still quite small:

 * file resources
 * exec resources
 * dependency edges that directly connect supported resources

Resources in classes and defines are considered, but containment, complex relationships, signaling edges etc.
are unsupported and/or untested.

Basically, a supported manifest can currently look like the following:

    file { 'a': ... } -> exec { 'b': ... } -> file { 'c': ... }

Anything more sophisticated will lead to erratic mileage.

## Compatibility

Supports Puppet `3.x` and `4.x`.

Supports `mgmt` 0.0.3 (no earlier releases)

## TODO

* more flexibility in the DSL
* easier DSL (e.g. add a method to get at the namevar)
* general fallback support using `puppet resource` (a.k.a. the Daenny hack)
