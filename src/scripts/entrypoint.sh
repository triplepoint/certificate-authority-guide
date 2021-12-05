#!/usr/bin/env sh
set -e

echo "********************************************************************"
echo "* Welcome to the Certificate Authority (CA) management environment"
echo "*"
echo "* For more information see the article at:"
echo "* https://triplepoint.github.io/certificate-authority-guide/"
echo "*"
echo "* Useful commands include:"
echo "* - archive_ca"
echo "* - verify_archive"
echo "*"
echo "* Run 'exit' to leave this environment and terminate this container"
echo "********************************************************************"
echo ""

if [ -f ${CA_ARCHIVE_DIR}/${CA_ROOT_ARCHIVE_FILENAME} ]; then
    # If the root CA archive is present, unpack it
    echo "--- Unarchiving root certificate authority..."
    mkdir -p ${CA_WORKING_DIR}
    tar -xf ${CA_ARCHIVE_DIR}/${CA_ROOT_ARCHIVE_FILENAME} -C ${CA_WORKING_DIR}
fi

if [ -f ${CA_ARCHIVE_DIR}/${CA_INTERMEDIATE_ARCHIVE_FILENAME} ]; then
    # If the intermediate archive is present, unpack it, potentially overwriting whatever was in
    # the root CA archive for the intermediate archive, if it was also present
    echo "--- Unarchiving intermediate certificate..."
    mkdir -p ${CA_WORKING_DIR}/intermediate
    tar -xf ${CA_ARCHIVE_DIR}/${CA_INTERMEDIATE_ARCHIVE_FILENAME} -C ${CA_WORKING_DIR}/intermediate
fi

if [ ! -f ${CA_ARCHIVE_DIR}/${CA_ROOT_ARCHIVE_FILENAME} ] && \
   [ ! -f ${CA_ARCHIVE_DIR}/${CA_INTERMEDIATE_ARCHIVE_FILENAME} ]; then
    # Else, create a clean skeleton working environment
    echo "--- Neither CA archive was present, creating new skeleton working environment..."
    mkdir -p ${CA_WORKING_DIR}
    cd ${CA_WORKING_DIR}
    mkdir -m 755 ./certs ./crl ./csr ./newcerts
    mkdir -m 700 ./private
    touch ./index.txt
    echo 1000 > ./serial
    echo 1000 > ./crlnumber
    cp ${OPENSSL_CNF_PATH} ./

    mkdir -p ${CA_WORKING_DIR}/intermediate
    cd ${CA_WORKING_DIR}/intermediate
    mkdir -m 755 ./certs ./crl ./csr ./newcerts
    mkdir -m 700 ./private
    touch ./index.txt
    echo 1000 > ./serial
    echo 1000 > ./crlnumber
    cp ${OPENSSL_CNF_PATH} ./
fi

echo "--- Ready."
echo ""

cd ${CA_WORKING_DIR}
exec "$@"
