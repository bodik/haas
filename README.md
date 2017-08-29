# HaaS - Honeypot as a Service -- Packaging and basic cluster management for flab.cesnet.cz honeypots

This software suite is designed to aid creating and maintaining cluster of
honeypots with warden transport.  It is based on masterless puppet and bash
automation.

<div align="center"><img style="max-width: 15em;" src="https://haas.cesnet.cz/logo.png"></div>



## Introduction

HaaS is project to create development and build environment for generating
honeypot VMs.

Based on [Warden project](https://warden.cesnet.cz) -- a system for efficient
sharing information about detected events (threats). Warden is a part of the
CESNET Large Infrastructure project developed by the [CESNET
association](https://www.cesnet.cz). The system enables CERTS/CSIRT teams (and
security teams in general) to share and make use of information on detected
anomalies in network and services operation generated by different systems –
IDS, honeypots, network probes, traffic logs, etc. – easily and efficiently.

HaaS uses masterless puppet, python, bash and Jenkins to generate VMs with
various preinstalled honeypots enabled for running and reporting to central
information exchange server.



## Basic honeypot node installation

1. prepare VM

   1. download VM ova image from [HaaS VM repository](https://haas.cesnet.cz/downloads)
	- check integrity using PGP key
		```
		address: haas-dev@cesnet.cz
		keyid: C801516B
		fingerprint: 33B8AE171C8E3D317121F57B32F0BAE1C801516B
		```

   2. import VM into virtualization platform

   3. configure networking and fully qualified domain name using one of the following procedures:

      - register MAC address of imported VM in DHCP and run the VM

      - boot the VM, login with default credentials `root:debian`, set proper
        IP address (`/etc/network/interfaces`) and fqdn (`/etc/hostname`),
        reboot VM

   4. finish base VM contextualization
     ```
     sh /puppet/jenkins/bin/haas_vm_prepare.sh
     ```

2. register client on warden server, receive a token (needed for obtaining
certificate). Follow [Warden participation](https://warden.cesnet.cz/en/participation#registration)

3. finalize VM configuration
```
sh /puppet/jenkins/bin/haas_vm_finalize.sh -w https://warden-hub.cesnet.cz/warden3 -n com.example.department.honeypot -t <token> 
```

4. reboot VM



## Honeypot node upgrade

1. backup appropriate `/opt/<honeypot>/racert` directory

2. prepare new VM from new image, see *Basic honeypot node installation 1 prepare VM*

3. restore appropriate `/opt/<honeypot>/racert` directory

4. finalize configuration of the new VM, see *Basic honeypot node installation 3 finalize VM configuration*

5. reboot VM



## Development

See [DEVELOPMENT.md](DEVELOPMENT.md)

