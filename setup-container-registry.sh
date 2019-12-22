#!/bin/bash

#  Setup a local private registry
#
#  Copyright (C) 2019 Thorsten Kukuk
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

LANG=C

REGISTRYDIR=/etc/registry
CERTDIR=/etc/registry/certs
USE_AUTH=1
USE_PORTUS=
FORCE_CLEAN=

show_help() {
        echo "setup-container-registry [--help|--no-auth|--portus][--force]"
        echo ""
        echo "This script will setup and enable a container registry using"
	echo "docker_auth for authentification and access control. By default"
	echo "everybody can list the catalog and pull images, but only an"
	echo "admin can push images. To enable this, a password needs to be"
	echo "set in the configuration file. The default configuration file"
	echo "can be found as /usr/etc/registry/auth_config.yml, modifications"
	echo "should be done on a copy in /etc/registry/auth_config.yml."
	echo ""
	echo "Options:"
	echo "  --no-auth"
	echo "      Don't install an autentication server"
        echo "  --portus"
	echo "      Use portus as authorization service and user interface"
	echo "  -f|--force"
	echo "      Delete everything in /etc/registry first"
	echo "  -h|--help"
	echo "      Display this help text"
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
        --no-auth)
            USE_AUTH=
            shift
            ;;
	-f|--force)
	    FORCE_CLEAN=1
	    shift
	    ;;
	-*)
	    show_help
	    exit 1
	    ;;
	*)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -n "$USE_PORTUS" -a -z "$USE_AUTH" ]; then
    echo "Error: --no-auth cannot be used together with --portus"
    exit 1
fi

if [ -n "$FORCE_CLEAN" ]; then
    echo "Deleting all content and subdirectories of ${REGISTRYDIR}!"
    rm -rf ${REGISTRYDIR}/*
fi

if [ -n "$USE_AUTH" ]; then
    if [ ! -d ${CERTDIR} ]; then
	echo "${CERTDIR} does not exist, creating self signed certificates"
	create-container-registry-certs --docker_auth
    fi

    # We need to copy the docker_auth template for the registry.
    if [ ! -f ${REGISTRYDIR}/config.yml ]; then
	MY_HOSTNAME=`hostname -f`
	sed -e "s|{your.registry.fqdn}|$MY_HOSTNAME|g" /usr${REGISTRYDIR}/config.yml.docker_auth > ${REGISTRYDIR}/config.yml
	chmod 644 ${REGISTRYDIR}/config.yml
    fi
    # XXX Copy the docker_auth config, too, needs a better solution
    if [ ! -f ${REGISTRYDIR}/auth_config.yml ]; then
	cp -a /usr${REGISTRYDIR}/auth_config.yml ${REGISTRYDIR}/
    fi

    systemctl enable container-registry
    systemctl enable registry-auth_server

    echo ""
    echo "Please adjust ${REGISTRYDIR}/auth_config.yml and start:"
    echo "  systemctl start container-registry"
    echo "  systemctl start registry-auth_server"

    exit 0
fi

if [ -n "$USE_PORTUS" ]; then
    if [ ! -d ${CERTDIR} ]; then
	echo "${CERTDIR} does not exist, creating self signed certificates"
	create-container-registry-certs --portus
    fi



    exit 0
fi

# Fallback, standalone registry without authentication
if [ ! -d ${CERTDIR} ]; then
    echo "${CERTDIR} does not exist, creating self signed certificates"
    create-container-registry-certs
fi

systemctl enable container-registry

echo "The container registry can be started by:"
echo "  systemctl start container-registry"
