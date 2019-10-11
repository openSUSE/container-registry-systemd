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

if [ ! -z USE_PORTUS ]; then
    # we create a setup for registry with portus
    REG_HOSTNAMES="localhost"
    if [ -n "$*" ]; then
	PORTUS_HOSTNAMES="$@"
    else
	PORTUS_HOSTNAMES=`hostname -f`
    fi
    PORTUS_IP_ADDRS=`getent ahosts ${PORTUS_HOSTNAMES} | awk '{print $1}' | sort -u`
    PORTUS_IP_ADDRS=`echo -n ${PORTUS_IP_ADDRS} | tr ' ' ','`
    PORTUS_HOSTNAMES=`echo -n ${PORTUS_HOSTNAMES} | tr ' ' ','`
    certstrap --depot-path ${CERTDIR} request-cert -ip ${PORTUS_IP_ADDRS} -domain ${PORTUS_HOSTNAMES} --passphrase "" --common-name portus
    certstrap --depot-path ${CERTDIR} sign portus --CA "ContainerRegistryCA"
else
    if [ -n "$*" ]; then
	REG_HOSTNAMES="$@"
    else
	REG_HOSTNAMES=`hostname -f`
    fi
fi

REG_IP_ADDRS=`getent ahosts ${REG_HOSTNAMES} | awk '{print $1}' | sort -u`
REG_IP_ADDRS=`echo -n ${REG_IP_ADDRS} | tr ' ' ','`
REG_HOSTNAMES=`echo -n ${REG_HOSTNAMES} | tr ' ' ','`

certstrap --depot-path ${CERTDIR} request-cert -ip ${REG_IP_ADDRS} -domain ${REG_HOSTNAMES} --passphrase "" --common-name registry
certstrap --depot-path ${CERTDIR} sign registry --CA "ContainerRegistryCA"
ln -sf ${CERTDIR}/ContainerRegistryCA.crt /etc/pki/trust/anchors/RegistryCA.pem
update-ca-certificates
