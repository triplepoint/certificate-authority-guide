---
title: More Details, and a Working Environment
---

# Operating Plan Details
TODO - talk about the database, and archiving


# Getting a Docker Execution Environment
In order to contain the infrastructure for provisioning these certificates, we'll build a Docker container in which we'll execute the various commands.

Setting up the Docker host environment is beyond the scope of this document, but a good place to start is the [Docker Community Edition website](https://www.docker.com/community-edition).

Clone this repository to a working directory:
``` shell
git clone https://github.com/triplepoint/ca-certificate-guide
cd ca-certificate-guide
```

Then build the [`Dockerfile`](https://github.com/triplepoint/ca-certificate-guide/blob/master/Dockerfile) into an image and create a Docker instance from the image with the usual Docker commands:
``` shell
docker build -t "ca-certificate-tools:latest" .

mkdir -p ./archives
docker run -it --rm  \
    --mount type=bind,source="$(pwd)/archives",target="/root/ca_persist" \
    ca-certificate-tools:latest
```
Here we're creating and mounting a `./archives` directory as a Docker volume.  This will be used for persisting archives of the generated files between Docker containers.  You might instead choose to directly mount a USB drive.

Be sure not to omit the `--rm` flag; this container will generate confidential files, and we want to destroy it once we've moved the generated confidential files to secure locations.

Unless specified otherwise, the commands in the rest of this guide are executed inside the context of this Docker image.
