#!/usr/bin/env sh
set -e

if [ -f ${CA_ARCHIVE_DIR}/ca_authority.tar.gz ]; then
    # If the root CA archive is present, use it and ignore the intermediate
    mkdir -p /root/ca
    tar -xf ${CA_ARCHIVE_DIR}/ca_authority.tar.gz -C /root/ca


elif [ -f ${CA_ARCHIVE_DIR}/intermediate_authority.tar.gz ]; then
    # Else, if the intermediate archive is present, unpack it
    mkdir -p /root/ca/intermediate
    tar -xf ${CA_ARCHIVE_DIR}/intermediate_authority.tar.gz -C /root/ca/intermediate

else
    # Else, create a clean skeleton working environment
    mkdir -p /root/ca
    cd /root/ca
    mkdir -m 755 ./certs ./crl ./csr ./newcerts
    mkdir -m 700 ./private
    touch ./index.txt
    echo 1000 > ./serial
    echo 1000 > ./crlnumber
    cp /opt/ca/ca_openssl.cnf ./

    mkdir -p /root/ca/intermediate
    cd /root/ca/intermediate
    mkdir -m 755 ./certs ./crl ./csr ./newcerts
    mkdir -m 700 ./private
    touch ./index.txt
    echo 1000 > ./serial
    echo 1000 > ./crlnumber
    cp /opt/ca/int_openssl.cnf ./
fi

cd /root/ca
exec "$@"
