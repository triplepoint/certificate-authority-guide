# Operational Overview
The [OpenSSL command line tool](https://www.openssl.org/docs/man1.1.1/man1/openssl.html) is the intimidating Swiss Army knife that performs practically all of the functions necessary for running a CA.  We'll only use a fraction of its features for this project.

In addition to generating keys and certificates and handling signing requests, OpenSSL can maintain a database of all the issued certificates signed by the CA.  Also, an incrementing serial number for issued certs can be kept to aid in auditing.  The database of issued certs and the serial number state are stored in text files alongside the certificates they describe, and these files will need to be preserved together with the CA certificates.

To do so, we'll generate one archive of the entire CA working set (`ca_authority.tar.gz`), and another for just the subset of files defining the intermediate certificate (`intermediate_authority.tar.gz`).  These archives can then be stored in separate safe locations between uses, allowing the less-risky intermediate authority certificate to be used to sign service certificates, without having to risk frequent access to the more dangerous root certificate.

## Setting Up a Docker Working Environment
In order to provide a self-contained repeatable infrastructure for operating the CA, we'll use Docker containers with the necessary tools pre-installed.  These short-lived containers can be destroyed and regenerated between CA duties, *as long as we're careful to archive the work done at the end of each session*.  We'll cover the details of doing so later in this guide.

Setting up a Docker host environment on your computer is beyond the scope of this document, but it's not especially difficult.  A good place to start is the [Docker Community Edition website](https://www.docker.com/community-edition).

Once you've got Docker installed, clone this site's code repository to a working directory:
``` bash
git clone https://github.com/triplepoint/certificate-authority-guide
```

Then with the provided helper script, build the [`Dockerfile`](https://github.com/triplepoint/certificate-authority-guide/blob/master/src/Dockerfile) into a Docker image and launch a Docker instance from that image:
``` bash
./src/scripts/run
```

If you inspect the above `run` script, in the `docker run` command, the `--mount` parameter is defining a local `source` directory (`./archives`) to mount as `/root/ca_persist` inside the Docker container.  This directory, shared between the host machine and the Docker container, is how we'll preserve the CA archives after we terminate the container.

When the above command is run, you'll have a Bash shell into that new container, in the container's `/root/ca` directory.  This is the working directory in which all the CA management work will take place.  The idea is that whatever work happens in here can be archived and moved (within the container) to `/root/ca_persist`, which will preserve it on the host machine after the container is terminated.

If the shared mount directory already has the `ca_authority.tar.gz` and/or `intermediate_authority.tar.gz` files present when the container is created, then these pre-existing archives will be unpacked into the `/root/ca` working directory on the Docker container when the container is created.  If both these archives are missing, then a new skeleton directory structure will be prepared.  Note that the root CA authority archive also contains the contents of the intermediate CA authority archive, and if both archive files are present in the shared mount, the root CA authority will take precedence.  See the Docker image's [`entrypoint.sh`](https://github.com/triplepoint/certificate-authority-guide/blob/master/src/scripts/entrypoint.sh) file for more details about what happens when the Docker container is created.

Remember, it's your responsibility to ensure that new work done inside the Docker container is archived _before_ the container is exited and destroyed.  We'll explain more about how to do this later in this guide.

Note that in the `run` script above, we're creating a local `./archives` directory to use as the `source` archive directory on the host.  You could instead provide the path to a mounted USB drive and avoid copying the archives onto your computer.  Be aware that Docker requires that path to be an absolute path.

Be sure not to omit the `--rm` flag; this container will generate confidential files, and we want to destroy it once we're done working inside the container and have safely re-created the archives.

## Verifying the Environment
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

At any point you can run `exit` to leave the docker container and destroy it.
