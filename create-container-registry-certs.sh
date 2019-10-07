#!/bin/sh
CERTDIR=/etc/registry/certs

LANG=C

if [ -n "$*" ]; then
  HOSTNAMES="$@"
else
  HOSTNAMES="`hostname -f; hostname` localhost"
fi

mkdir -p ${CERTDIR}

IP_ADDRS=`getent ahosts ${HOSTNAMES} | awk '{print $1}' | sort -u`
IP_ADDRS=`echo -n ${IP_ADDRS} | tr ' ' ','`
HOSTNAMES=`echo -n ${HOSTNAMES} | tr ' ' ','`

certstrap --depot-path ${CERTDIR} init --common-name "ContainerRegistryCA" --passphrase ""
certstrap --depot-path ${CERTDIR} request-cert -ip ${IP_ADDRS} -domain ${HOSTNAMES} --passphrase "" --common-name registry
certstrap --depot-path ${CERTDIR} sign registry --CA "ContainerRegistryCA"
ln -sf ${CERTDIR}/ContainerRegistryCA.crt /etc/pki/trust/anchors/RegistryCA.pem
update-ca-certificates
