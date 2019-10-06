#!/bin/sh
CERTDIR=/etc/registry/certs

if [ ! -n "$*" ]; then
  HOSTNAMES="$@"
else
  HOSTNAMES=`hostname -f`
fi

mkdir -p ${CERTDIR}
certstrap --depot-path ${CERTDIR} init --common-name "ContainerRegistryCA" --passphrase ""
certstrap --depot-path ${CERTDIR} request-cert -ip 192.168.107.90 -domain microos.demo --passphrase ""
certstrap --depot-path ${CERTDIR} sign microos.demo --CA "ContainerRegistryCA"
ln -sf ${CERTDIR}/ContainerRegistryCA.crt /etc/pki/trust/anchors/RegistryCA.pem

