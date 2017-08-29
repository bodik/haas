# HaaS development information

Masterless puppet ecosystem is split into set of components installable on
almost any Debian 9.x Stretch VM.

## Components

Each major component should provide a puppet module and set of install/check
and other scripts within itself.

```
component/			-- puppet module
component/fileX			-- additional file (perhaps a script)
component/tests/componentX.sh	-- simple test checking real state of the service
  				   typically used by jenkins autotests

component.install.sh		-- script for masterless installation
component.check.sh		-- script for state detection (noop show_diff)
```

## Use-Cases

### Ops/Maintenance

Bootstrap suite from a git repository, subsequent calls will pull from master repo.

```
wget https://haas.cesnet.cz/haas.git/bootstrap.install.sh && sh bootstrap.install.sh
cd /puppet && ls -l
sh bootstrap.install.sh
```

During ops, components/roles can be installed on managed node or the state of
installed component can be checked by component selftest or puppet itself.

```
sh componentX.install.sh 		## install a component
sh component/tests/component.sh		## run a component selftest

pa.sh -e 'class {"glog::glog2": }'	## use component directly by puppet
```

Lately, a state of node can change, perhaps by rutime tuning or more
development. A `check_stddev.sh` can be used to check changed things within the
system. All available component's .check.sh will be called.

```
sh check_stddev.sh
```

Changes can be accepted into repository or node state could be reverted to origial state.

``` 
cp /etc/fileX component/templates/fileX
vim component/manifests/subclass.pp
sh check_stddev.sh
git status
git commit
```

### Example installation of ELK analytics node

Following commands will ensure installation of basic components for data analysis.
(elasticsearch data node, logstash processor, kibana frontend).

```
wget https://haas.cesnet.cz/haas.git/bootstrap.install.sh && sh bootstrap.install.sh
cd /puppet && ls -l
sh phase2.install.sh
sh glog2.install.sh
sh glog/tests/glog2.sh
links https://$(facter fqdn)/haas/test/dash.html
```
 
### Example installation of testing warden-server development node

Commands will ensure installation of all components needed for running basic
warden-server node along with warden_ca and glog2 analytics.

```
wget https://haas.cesnet.cz/haas.git/bootstrap.install.sh && sh bootstrap.install.sh
cd /puppet && ls -l
sh phase2.install.sh
sh metalib/tests/phase2.sh

sh lamp.install.sh
sh lamp/tests/lamp.sh
sh warden3-server.install.sh
sh warden3/tests/server.sh
sh glog2.install.sh
sh glog/tests/glog2.sh
```

### Example installation of visualization node

```
wget https://haas.cesnet.cz/haas.git/bootstrap.install.sh && sh bootstrap.install.sh
cd /puppet && ls -l
sh phase2.install.sh
sh metalib/tests/phase2.sh
reboot

sh lamp.install.sh
sh lamp/tests/lamp.sh
sh glog2.install.sh
sh glog/tests/glog2.sh
pa.sh -e 'warden3::cert { "cz.cesnet.haas.test.tologstash": destdir => "/opt/tologstash/racert", token=>"ABCDEFG"} '
pa.sh -e 'class { "warden3::tologstash": warden_client_name=> "cz.cesnet.haas.test.tologstash", warden_server_url=>"https://warden-hub.cesnet.cz/warden3-sandbox" }
```

## Automating tasks with (Robert) Jenkins

While maintaining a small site can be done by hand as shown in previous
chapter, large environment can use modules/components through standard
puppetmaster, but neither approach is suitable for fast development iterations
or creating an ad-hoc experiment environment (like performance or acceptance
testing).

Sometimes a more complex tasks are needed to be automated -- eg. creating an
rsyslog server, 2 clients, spawning a test and archiving outputs and artefacts
for latter use. In our case Jenkins is runing on private VM, equiped with
user's credentials and performing tasks towards available clouds and
provisioned VMs. More documentation can be found in separate Jenkins component
documentation.

## Available components

* [metalib](https://github.com/bodik/haas/tree/master/metalib/)
  * [iptables](https://github.com/bodik/haas/tree/master/iptables/)
* [jenkins](https://github.com/bodik/haas/tree/master/jenkins/)
* [lamp](https://github.com/bodik/haas/tree/master/lamp/)
* [gmysql](https://github.com/bodik/haas/tree/master/gmysql/)
* [glog](https://github.com/bodik/haas/tree/master/glog/)
* [warden3-server](https://github.com/bodik/haas/tree/master/warden3/)
  * [warden3-tologstash](https://github.com/bodik/haas/tree/master/warden3/)
  * [hpcowrie](https://github.com/bodik/haas/tree/master/hpcowrie/)
  * [hpdio](https://github.com/bodik/haas/tree/master/hpcowrie/)
  * [hpjdwpd](https://github.com/bodik/haas/tree/master/hpjdwpd/)
  * [hptelnetd](https://github.com/bodik/haas/tree/master/hptelnetd/)
  * [hpucho](https://github.com/bodik/haas/tree/master/hpucho/)

