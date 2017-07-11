# HaaS - Honeypot as a Service -- Packaging and basic cluster management for flab.cesnet.cz honeypots

This software suite is designed to aid creating and maintaining cluster of
honeypots with warden transport.  It is based on masterless puppet and bash
automation.

### Acknowledgement

Computational resources were provided by the MetaCentrum under the program
LM2010005 and the CERIT-SC under the program Centre CERIT Scientific Cloud,
part of the Operational Program Research and Development for Innovations, Reg.
no. CZ.1.05/3.2.00/08.0144.



## Introduction

HaaS is project to create develompment and build environment for generating
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
  1. download VM ova image from [TODO:repository](TODO)
  2. import VM into virtualization platform

  3. configure networking and fully qualified domain name using one of the following procedures:

     - register MAC address of imported VM in DHCP and run the VM

     - boot the VM, login with default credentials `root:debian`, set proper IP address (`/etc/network/interfaces`) and fqdn (`/etc/hostname`), reboot VM

  4. finish base VM contextualization
     ```
     cd /puppet
     sh phase2.install.sh
     reboot
     ```

3. generate host certificate
```
sh /puppet/warden3/bin/haas_init.sh
```
4. let Warden acknowleded certification authority sign it and place result under `/opt/hostcert/<FQDN>.crt`

5. [get client registered](https://warden.cesnet.cz/en/participation#registration) at Warden server

6. finalize VM configuration
```
sh /puppet/warden3/bin/haas_finalize.sh
```

7. reboot VM



## Development

See [DEVELOPMENT.md](DEVELOPMENT.md)

