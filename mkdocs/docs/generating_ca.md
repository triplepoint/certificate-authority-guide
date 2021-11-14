# Building a Certificate Authority
## A Note on the OpenSSL Config Files
In our skeleton CA file structure, we've provided a copy of the openssl config file in both the `/root/ca` and `/root/ca/intermediate` directory.  These files are identical, but they're duplicated to ensure that the intermediate CA archive has its own copy if it's ever used on its own (for example, when signing a service certificate).  If for any reason you modify one of these files, be sure to similarly modify the other one.

We'll be careful below to explicitly set the openssl `-config` and `-name` flags for each scenario, but just be aware these two files are (or at least should be) identical.

## Generating a Root CA Certificate
The Certificate Authority's core documents are its root certificate and the associated private key.  This is the certificate which all clients will directly trust, and it's the root of the chain of trust that ultimately extends down to the individual service certificates.

You'll (hopefully) only need to generate this root certificate and its key once.  We'll set the expiration for ~25 years (9130 days), and as long as the certificate isn't compromised and you don't make any mistakes, you can rely on it to function for that long.

### Generate a new Key for the CA Root Certificate
First, we need to generate a new RSA key for the CA certificate.  The key will be encrypted with a passphrase, which you'll be prompted to supply.  You'll want to use a real non-empty password for this key and store it in a safe place.

``` bash
openssl genrsa \
    -aes256 \
    -out /root/ca/private/ca.key.pem \
    4096 && \
chmod 400 /root/ca/private/ca.key.pem
```

This generates the new CA key at `/root/ca/private/ca.key.pem`.

### Generate a Certificate Signing Request for the CA Root Certificate
Next, we need to generate a Certificate Signing Request (CSR) which will define the details of the CA certificate, and which will be used to self-sign the new certificate.

When you are prompted for the CA Certificate Distinguished Name details, take care to get them right.  You won't want to regenerate the certificate after it's been distributed.

``` bash
openssl req \
    -config /root/ca/ca_openssl.cnf \
    -key /root/ca/private/ca.key.pem \
    -new \
    -sha256 \
    -out /root/ca/ca.req.pem
```

This generates the new CSR for the root certificate at `/root/ca/ca.req.pem`.

### Self-Sign the Root Certificate
Now that we have the key and a signing request, we can act on the request to self-sign the root certificate:

``` bash
openssl ca \
    -config /root/ca/ca_openssl.cnf \
    -name CA_root \
    -in /root/ca/ca.req.pem \
    -create_serial \
    -out /root/ca/certs/ca.cert.pem \
    -days 9130 \
    -keyfile /root/ca/private/ca.key.pem \
    -selfsign \
    -extensions v3_ca
```
This generates the new CA root certificate at `/root/ca/certs/ca.cert.pem`.  When you are prompted about "committing" say `y`; this is about starting a database of certificates signed by this authority.

### Verifying the Root Certificate
Now that the root CA certificate and key are generated, you can verify them with:
``` bash
openssl x509 -noout -text -in /root/ca/certs/ca.cert.pem
```

TODO - what are we looking at?

## Generating an Intermediate CA Certificate
### Generate a New Key for the Intermediate Certificate
Similar to what we did for the CA root certificate above, we need to generate a signing key for the CA intermediate certificate. Once again, you'll need to use a non-empty secure password and store it in a secure place:
``` bash
openssl genrsa \
    -aes256 \
    -out /root/ca/intermediate/private/intermediate.key.pem \
    4096 && \
chmod 400 /root/ca/intermediate/private/intermediate.key.pem
```
This generates the new intermediate certificate key at: `/root/ca/intermediate/private/intermediate.key.pem`.

### Generate a Certificate Signing Request for the Intermediate Certificate
This document represents a request to the root CA to generate the signed intermediate certificate.

Note that the `Country Name`, `State or Province Name`, and `Organization Name` all have to match the values of the root CA certificate.

Also note that the Common Name used in this CSR _must_ be distinct from the root CA certificate's Common Name, used above.

``` bash
openssl req \
    -config /root/ca/intermediate/int_openssl.cnf \
    -key /root/ca/intermediate/private/intermediate.key.pem \
    -new \
    -sha256 \
    -out /root/ca/intermediate/csr/intermediate.csr.pem
```

### Sign the Intermediate Certificate with the CA Certificate
Now we can sign the intermediate certificate with the root certificate and the root certificate's key:
``` bash
openssl ca \
    -config /root/ca/ca_openssl.cnf \
    -in /root/ca/intermediate/csr/intermediate.csr.pem \
    -notext \
    -out /root/ca/intermediate/certs/intermediate.cert.pem \
    -days 3650 \
    -md sha256 \
    -extensions v3_intermediate_ca && \
chmod 444 /root/ca/intermediate/certs/intermediate.cert.pem
```
Answer `y` to any prompts about "commiting", this is about the database of signed certificates that OpenSSL is keeping for us (see below).
This generates the new Intermediate certificate at: `/root/ca/intermediate/certs/intermediate.cert.pem`.

Note here that we're giving the intermediate certificate a 10 year (3650 day) lifetime.

### Verifying the Intermediate Certificate
Once generated, you can verify the certificate's values with:
``` bash
openssl x509 \
    -noout \
    -text \
    -in /root/ca/intermediate/certs/intermediate.cert.pem
```

And you can verify the intermediate certificate's chain of trust against the CA certificate is valid with:
``` bash
openssl verify \
    -CAfile /root/ca/certs/ca.cert.pem \
    /root/ca/intermediate/certs/intermediate.cert.pem
```

## Creating a Chain File
It's often convenient to have a combined "chain file" for a given service certificate, to represent in one place the complete chain of trust back to a trusted root certificate.  Many SSL/TLS configurations expect to have these files.

These chain files are simply the concatenated set of all the certificates in the chain of trust which lead back to the trusted CA root certificate:
``` bash
cat /root/ca/intermediate/certs/intermediate.cert.pem \
    /root/ca/certs/ca.cert.pem > \
    /root/ca/intermediate/certs/ca-chain.cert.pem && \
chmod 444 /root/ca/intermediate/certs/ca-chain.cert.pem
```

These are all of the CA's public certificates, so it's safe to distribute this `/root/ca/intermediate/certs/ca-chain.cert.pem` file to the services with the service certificates.

## Safe Storage
The above work has generated several files which so far only exist on this Docker container, and which now need to be preserved:

- The CA root certificate and its associated key file
- The CA intermediate certificate and its associated key file
- The chain file combining both certificates
- A set of `index.txt*` and `serial*` files, one for each of the two CA certificates, which track what certificates have been signed with which CA certificates
- The `*openssl.cnf` files, one for each CA certificate, which configured OpenSSL during the various operations

While not all of these files are confidential information, they should all nonetheless be packaged together and prepared for storage.  This ensures that over the years, you can reliably rebuild this working environment to perform certificate-related tasks.

We'll package the entire working set up into one archive at `/root/ca_authority.tar.gz`.  This file contains everything needed to operate the CA, and therefore should be  stored in a seldom-accessed, higher-security location.

We'll also package just the intermediate authority's files into a separate archive at `/root/intermediate_authority.tar.gz`.  Of the two archives, this is the file we'll use the most, since it's all that's necessary for managing service SSL/TLS certificates.  It can be stored in the more-convenient, less-secure site.

Remember to store both keys' passwords somewhere safe as well.

We can create the archives like this:
``` bash
tar -czvf /root/ca_authority.tar.gz -C /root/ca/ .
cp /root/ca_authority.tar.gz /root/ca_persist

tar -czvf /root/intermediate_authority.tar.gz -C /root/ca/intermediate/ .
cp /root/intermediate_authority.tar.gz /root/ca_persist
```

Because this "export" behavior is critical, the above shell commands are also provided on the Docker image as a script named [`archive_ca`](https://github.com/triplepoint/certificate-authority-guide/blob/master/src/scripts/archive_ca).  You can call this command at any time to archive the working set back to the persistent directory on the Docker host:
``` bash
archive_ca
```

A verification script named [`verify_archive`](https://github.com/triplepoint/certificate-authority-guide/blob/master/src/scripts/verify_archive).  Is also provided to compare the archives contents to the working copy, and warn you if any changes are present in the latter that would be lost if you exited the container shell.

As a final note: as the intermediate archive is used without the presence of the root authority archive, it will accrue records in its signed-certificates database and Certificate Revocation List which won't be present in the root authority archive.  Periodically, the `intermediate/` directory in the root CA archive will need to be refreshed with the contents of the `intermediate_authority` archive.  As the two archives are overlaid when both are present during unarchival, this can be accomplished by having both archives present, creating the container with `./scripts/run`, and then running `archive_ca` to refresh the archive contents.
