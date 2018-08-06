#!/usr/bin/env sh

# The dockerfile set up a generic set of directories for starting
# fresh, but if the archives are present in the volume mount, we should
# use those instead.
# TODO - untar the storage archives into the working directories

# Make sure the CMDs are executed in the right directory
cd /root/ca

exec "$@"
