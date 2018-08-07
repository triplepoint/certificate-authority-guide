---
title: Introduction
---

# Introduction
A typical office or enthusiast LAN will have several web services hosted on private domain names which only resolve on the LAN.  We'd like these services to use HTTPS, with SSL/TLS certificates which have valid chains of trust, but we don't want to get a real-world Certificate Authority (CA) involved in issuing our service certificates.

The solution is to create our own CA.  This entity represents a new root point of trust which our client hosts can explicitly trust, and which can extend a valid chain of trust to the various internal web service SSL/TLS certificates.

However, this plan has important implications for security and privacy.  Trusting any CA implies that any certificate signed by that CA is also trusted.  This broad trust could be exploited to issue fraudulent certificates for 3rd party domains if, say, the CA certificate and key were stolen, or if the agency which controls the CA chose to undermine the privacy and security of the clients who trusted it.

In order to mitigate this risk, we'd like to limit the CA such that its trust only extends to domains which match a given whitelist.  Clients can then verify this condition by inspecting the CA certificate before trusting it, and be assured that, at worst, their attack surface extends only to a small set of internal domains.

In addition, as a matter of security best practices, we'd like to recognize the tradeoff between convenience and security when it comes to storing the CA certificate's key, and optimize for security.  In order to do so, while still enabling convenient signing of new service certificates, we'd like to have an intermediate certificate signed by the root CA certificate, which is then used for signing the various web service certificates.  This allows us to avoid the need for frequent access to the root CA certificate's key, and also enables us to revoke the intermediate CA certificate if it were compromised, while allowing for a more convenient (though still secure) storage strategy for the intermediate CA certificate's key.

Specifically, we want:
- A single long-lived root CA certificate, limited to just internal production domains with [X.509 Name Constraints](https://tools.ietf.org/html/rfc5280#section-4.2.1.10), which can be trusted by internal clients.
- An intermediate CA certificate, signed by the root CA certificate.
- Various SSL/TLS service certificates for each of the production services on the internal network, signed by the intermediate CA certificate.

The rest of this guide will go into detail on how to accomplish these goals, and some advice on maintaining it with a minimum of hassle.
