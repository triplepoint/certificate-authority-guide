# Operational Overview
The [OpenSSL command line tool](https://www.openssl.org/docs/man1.1.0/apps/openssl.html) is the intimidating Swiss Army knife that performs practically all of the functions necessary for running a CA.  We'll only use a fraction of its features for this project.

In addition to generating keys and certificates and handling signing requests, OpenSSL can maintain a database of all the issued certificates signed by the CA.  Also, an incrementing serial number for issued certs can be kept to aid in auditing.  The database of issued certs and the serial number state are stored in text files alongside the certificates they describe, and these files will need to be preserved together with the CA certificates.

To do so, we'll generate one archive of the entire CA working set (`ca_authority.tar.gz`), and another for just the subset of files defining the intermediate certificate (`intermediate_authority.tar.gz`).  These archives can then each have a backup and storage policy customized for their different use cases.

# Setting Up a Docker Working Environment
In order to provide a self-contained repeatable infrastructure for operating the CA, we'll use Docker containers with the necessary tools pre-installed.  These containers can be destroyed and regenerated between CA duties, *as long as we're careful to archive the work done at the end of each session*.  We'll cover the details of doing so later in this guide.

Setting up a Docker host environment on your computer is beyond the scope of this document, but it's not especially difficult.  A good place to start is the [Docker Community Edition website](https://www.docker.com/community-edition).

Once you've got Docker installed, clone this site's code repository to a working directory:
``` shell
git clone https://github.com/triplepoint/certificate-authority-guide

cd certificate-authority-guide/src
```

Then build the [`Dockerfile`](https://github.com/triplepoint/certificate-authority-guide/blob/master/src/Dockerfile) into a Docker image and create a Docker instance from that image with the typical Docker commands:
``` shell
# Create a shared directory for exposing the CA archives inside the container
mkdir archives

# Generate a Docker image from the provided Dockerfile
docker build -t "certificate-authority-tools:latest" .

# Start a Docker container from the image we generated above
docker run -it --rm  \
    --mount type=bind,source="$(pwd)/archives",target="/root/ca_persist" \
    certificate-authority-tools:latest
```

In the above `docker run` command, the `--mount` parameter is defining the directory we created above at `./archives` as the `source` directory to mount as `/root/ca_persist` inside the Docker container.  This directory shared between the host machine and the Docker container is how we'll move the CA archives in and out of the working container.

If the `source` directory already has the `ca_authority.tar.gz` and/or `intermediate_authority.tar.gz` files present when the container is started, then these pre-existing archives will be unpacked into the `/root/ca` working directory on the Docker container.  If these archives are missing, then a new skeleton directory structure will be prepared.  Note that the root CA authority archive contains a copy of all the files that are in the intermediate CA authority archive, and if both archives are present, the root CA authority will take precedence and the intermediate authority archive will be ignored.

Remember, it's your responsibility to ensure that new work done inside the Docker container is archived _before_ the container is exited and destroyed.

Note that in the command example above, we're creating a local `./archives` directory to use as the `source` archive directory on the host.  You could instead provide the path to a mounted USB drive and avoid copying the archives onto your computer.  Note that Docker requires that path to be an absolute path.

Be sure not to omit the `--rm` flag; this container will generate confidential files, and we want to destroy it once we've moved the archived files to secure locations.

# Verification
Before we move on to setting up our Certificate Authority, go ahead and run the commands above and ensure that you've got a command prompt inside the Docker container.  You can verify things are set up properly by running the `pwd` and `tree` commands to see which directory you're in, and whether the skeleton root CA authority is set up:

``` bash
root@b802e56f10b6:~/ca# pwd
/root/ca
root@b802e56f10b6:~/ca# tree
.
|-- ca_openssl.cnf
|-- certs
|-- crl
|-- crlnumber
|-- csr
|-- index.txt
|-- intermediate
|   |-- ca_openssl.cnf
|   |-- certs
|   |-- crl
|   |-- crlnumber
|   |-- csr
|   |-- index.txt
|   |-- newcerts
|   |-- private
|   `-- serial
|-- newcerts
|-- private
`-- serial

11 directories, 8 files
```

Unless specified otherwise, the commands in the rest of this guide are executed inside the context of this Docker image.
