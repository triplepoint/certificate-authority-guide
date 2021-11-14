FROM ubuntu:focal
LABEL maintainer="Jonathan Hanson <jonathan@jonathan-hanson.org>"

# The path on the container to which the persistent archive directory is mounted
# Note that this must match the define in the `run` helper script
ENV CA_ARCHIVE_DIR /root/ca_persist

# The name of the Root Certificate Authority archive file
ENV CA_ROOT_ARCHIVE_FILENAME ca_authority.tar.gz

# The name of the Intermediate Certificate archive file
ENV CA_INTERMEDIATE_ARCHIVE_FILENAME intermediate_authority.tar.gz

# The path of the working directory in which we'll unpack and repack the CA files
ENV CA_WORKING_DIR /root/ca

# The full path where we'll install the ca_openssl.cnf configuration file
ENV OPENSSL_CNF_PATH /opt/ca/ca_openssl.cnf


# Establish the mount point for the CA archive directory
VOLUME ["$CA_ARCHIVE_DIR"]

# Install the tools we'll need
RUN apt-get update && apt-get install -y \
        openssl \
        tree \
        vim \
    && rm -rf /var/lib/apt/lists/*

# Copy over the stock prepared OpenSSL config file
# Note that this will only be used if the archives don't have their own copies
COPY conf/ca_openssl.cnf $OPENSSL_CNF_PATH

# A quick helper script for generating archives
COPY scripts/archive_ca /usr/local/bin/archive_ca
RUN chmod 755 /usr/local/bin/archive_ca

# A quick helper script for generating archives
COPY scripts/verify_archive /usr/local/bin/verify_archive
RUN chmod 755 /usr/local/bin/verify_archive

# The script to execute as soon as the container is created
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
