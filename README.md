# Run your own private registry

This repository contains everything to run the openSUSE container registry
image on a systemd based Linux distribution, preferable [openSUSE
MicroOS](https://en.opensuse.org/Kubic:MicroOS) or [openSUSE
Kubic](https://kubic.opensuse.org/).

## Quick Installation

### Certificates

The script `create-container-registry-certs` creates self signed certificates
for the registry in `/etc/registry/certs`. It takes as arguments the names
under which the registry should be reachable. If no argument is given,
"localhost" and the local hostname are used. The script makes the CA
certificate known to the local system. On every machine which should connect
to this private registry, the file
`/etc/registry/certs/ContainerRegistryCA.crt` needs to be copied to
`/etc/pki/trust/anchors/ContainerRegistryCA.pem` and `update-ca-certificates`
needs to be called.


### Start Registry

`systemctl start container-registry` will pull and start the
registry. `systemctl status container-registry` should show a successful
running registry and a command like `reg ls localhost` should be able to
connect to it.
Now the registry can be used.

## Advanced Setup

### Certificate

Since https is used to communicate with the registry by tools like docker,
podman and cri-o, certificates are required to start the registry. An official
certificate should be preferable requested, but a self signed as described
above should work for the start, too. The certificate needs to be stored in
`/etc/registry/certs` as `registry.crt` and `registry.key`. Different names
are possible, but in this case, `/usr/etc/registry/config.yml` needs to be
copied to `/etc/registry` and adjusted. The directory `/etc/registry/certs`
cannot be changed, else the container with the registry cannot access the
certificates anymore.
It is not necessary to distribute the public CA key to all machines with an
official certificate.

### Configuration File

The configuration file for the container registry can be found at
`/usr/etc/registry/config.yml`. If changes should be made, the file needs to
be copied to `/etc/registry/config.yml`. In this case, the administrator is
responsible to merge distribution made changes in
`/usr/etc/registry/config.yml`.
The registry needs to be restarted so that the changes can take effect.

### Sysconfig File

The file `/etc/sysconfig/container-registry` is read by the systemd service
file and contains variables to run the registry container.

* REGISTRY_IMAGE_PATH describes where the container registry image can be found.
* EXTERNAL_PORT defines the port, under which the registry is reacheable.
* STOARGE_DIR defines the directory, where the images are stored.
