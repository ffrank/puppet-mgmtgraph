# Alpha releases

#### 0.6.0 2020-01-31

* replaces the `puppet yamlresource` workaround with `pippet` per default
* adds the `--no-pippet` option for backwards compatibility
* raises version requirement for ffrank-yamlresource to 0.2.0
* raises version requirement for mgmt to 0.0.21 for full support

#### 0.5.0 2020-01-29

* drop watchcmd from the "puppet resource" default translation
* drop support for mgmt < 0.0.16

#### 0.4.5 2020-01-26

* fixes a metadata issue wrt. ffrank-yamlresource

#### 0.4.4 2020-01-26

* converted to PDK format
* drop Puppet 4 support in favor of Puppet 6

#### 0.4.3 2019-11-11

* supports more parameters to `exec`
* add support for `mount`, `user`, `group`

#### 0.4.2 2019-02-12

 * documentation improvements
 * avoid spawning parameters when they get no value
 * fix an issue where the application would abort with certain inputs
 * add support for Puppet 6.x
 * made sure to not try and run on Puppet 3 and older
 * no longer warns when files use the default filebucket option
 * fix issue with failing translations

This release contains contributions by James Shubin (@purpleidea)

Thanks!

#### 0.4.1 2018-03-09

 * add missing documentation

#### 0.4.0 2018-03-09

 * remove Puppet 3 support (not broken, just no longer tested)
 * add the stats subcommand
 * support more mgmt features (now requires mgmt 0.0.8)
 * some fixes and improvements in edge case handling
 * new resource type support: augeas, ec2_instance
 * fix a bug with translating service resources
 * fix metaparameter handling in the fallback pseudo-translator

This release contains code written by Johan Bloemberg (@aequitas).

Thanks for the contribution!

#### 0.3.1 2017-02-20

 * translate `notify` resources to mgmt's `msg`
 * add the `--conservative` flag

#### 0.3.0 2016-08-19

 * turn resources that `mgmt` does not support into `exec puppet yamlresource` vertices
 * print warnings about attributes that cannot be translated
 * drop test coverage with Ruby 1.9.3
 * ignore `notify` resources in the input
 * adopt a dependency on the `ffrank-yamlresource` module

The idea to handle unsupported resources this way is from Daniele Sluijters (@daenney).

#### 0.2.3 2016-07-12

 * (#1) support relationships with classes and insances of defined types

#### 0.2.2 2016-06-22

 * generate a `watchcmd` in `exec` resources based on Puppet's `runinterval`
 * fix the `package` type translation
 * support `ensure => directory` in `file` resources
 * generate deterministic names for relationship edges
 * some bug- and doc fixes

This release contains contributed code from James Shubin.

#### 0.2.1 2016-05-09

 * support service resources
 * support package resources
 * more flexible support for relationship edges

#### 0.2.0 2016-03-30

 * (breaking) move output format from mgmt 0.0.2 to 0.0.3
 * add mgmt compatibility information to README

#### 0.1.0 2016-03-15

 * switch implementation to the faces API
 * add a DSL for defining resource translation rules
 * add basic infrastructure like tests, README, metadata etc.

# Pre-releases

#### 0.0.1 2016-02-24

 * initial publication
