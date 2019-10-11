#!/bin/bash
CERTDIR=/etc/registry/certs
LANG=C
USE_PORTUS=

show_help() {
	echo "create-container-registry-certs [--help|--portus]"
	echo ""
	echo "Script to create self signed certificates for a container"
	echo "registry and optional portus"
	echo ""
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
	-h|--help)
	    show_help
	    exit 0
	    ;;
	-p|--portus)
	    USE_PORTUS=1
	    shift
	    ;;
	*)    # unknown option
	    POSITIONAL+=("$1") # save it in an array for later
	    shift # past argument
	    ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

mkdir -p ${CERTDIR}
# Create CA certificate
certstrap --depot-path ${CERTDIR} init --common-name "ContainerRegistryCA" --passphrase ""

if [ -n "$*" ]; then
  HOSTNAMES="$@"
else
  HOSTNAMES="`hostname -f; hostname` localhost"
fi

IP_ADDRS=`getent ahosts ${HOSTNAMES} | awk '{print $1}' | sort -u`
IP_ADDRS=`echo -n ${IP_ADDRS} | tr ' ' ','`
HOSTNAMES=`echo -n ${HOSTNAMES} | tr ' ' ','`

if [ ! -z USE_PORTUS ]; then
    certstrap --depot-path ${CERTDIR} request-cert -ip ${IP_ADDRS} -domain ${HOSTNAMES} --passphrase "" --common-name portus
    certstrap --depot-path ${CERTDIR} sign portus --CA "ContainerRegistryCA"
fi

certstrap --depot-path ${CERTDIR} request-cert -ip ${IP_ADDRS} -domain ${HOSTNAMES} --passphrase "" --common-name registry
certstrap --depot-path ${CERTDIR} sign registry --CA "ContainerRegistryCA"

ln -sf ${CERTDIR}/ContainerRegistryCA.crt /etc/pki/trust/anchors/ContainerRegistryCA.pem
update-ca-certificates
