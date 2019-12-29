#!/bin/bash
CERTDIR=/etc/registry/certs
LANG=C
USE_PORTUS=
FORCE=0

show_help() {
    echo "create-container-registry-certs [--help|--portus|--docker_auth][--force]"
    echo ""
    echo "Script to create self signed certificates for a container"
    echo "registry and optional portus"
    echo ""
    echo "Options:"
    echo "  -f|--force        Overwrite existing CA certificate"
    echo "  -a|--docker_auth  Create additional a certificate for docker_auth"
    echo "  -p|--portus       Create additional a certificate for Portus"
    echo "  -h|--help         Print this help text"
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
	-a|--docker_auth)
	    USE_DOCKER_AUTH=1
	    shift
	    ;;
	-f|--force)
	    FORCE=1
	    shift
	    ;;
	*)    # unknown option
	    POSITIONAL+=("$1") # save it in an array for later
	    shift # past argument
	    ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ ${FORCE} -eq 1 -o ! -f ${CERTDIR}/ContainerRegistryCA.crt ]; then
    mkdir -p ${CERTDIR}
    rm -f ${CERTDIR}/ContainerRegistryCA.*
    # Create CA certificate
    certstrap --depot-path ${CERTDIR} init --common-name "ContainerRegistryCA" --passphrase ""
fi

if [ -n "$*" ]; then
    HOSTNAMES="$@"
else
    HOSTNAMES="`hostname -f; hostname` localhost"
fi

IP_ADDRS=`getent ahosts ${HOSTNAMES} | awk '{print $1}' | sort -u`
IP_ADDRS=`echo -n ${IP_ADDRS} | tr ' ' ','`
HOSTNAMES=`echo -n ${HOSTNAMES} | tr ' ' ','`

if [ ! -z "${USE_PORTUS}" ]; then
    rm -f ${CERTDIR}/portus.*
    certstrap --depot-path ${CERTDIR} request-cert -ip ${IP_ADDRS} -domain ${HOSTNAMES} --passphrase "" --common-name portus
    certstrap --depot-path ${CERTDIR} sign portus --CA "ContainerRegistryCA"
fi
if [ ! -z "${USE_DOCKER_AUTH}" ]; then
    rm -f ${CERTDIR}/auth_server.*
    certstrap --depot-path ${CERTDIR} request-cert -ip ${IP_ADDRS} -domain ${HOSTNAMES} --passphrase "" --common-name auth_server
    certstrap --depot-path ${CERTDIR} sign auth_server --CA "ContainerRegistryCA"
fi

rm -f ${CERTDIR}/registry.*
certstrap --depot-path ${CERTDIR} request-cert -ip ${IP_ADDRS} -domain ${HOSTNAMES} --passphrase "" --common-name registry
certstrap --depot-path ${CERTDIR} sign registry --CA "ContainerRegistryCA"

ln -sf ${CERTDIR}/ContainerRegistryCA.crt /etc/pki/trust/anchors/ContainerRegistryCA.pem
update-ca-certificates
