# Test-SSLCertificate

Verifies the entire certificates chain from a certificate object or hostname.

## Parameters

### Parameter Set 1

- `[X509Certificate2]` **Certificate** _An X509Certificate2 certificate object._ Mandatory, ValueFromPipeline
- `[Switch]` **RevocationMode** _The Revocation Mode to use in validation.
NoCheck: No revocation check is performed on the certificate.
Offline: A revocation check is made using a cached certificate revocation list (CRL).
Online: A revocation check is made using an online certificate revocation list (CRL)._ 

### Parameter Set 2

- `[Switch]` **RevocationMode** _The Revocation Mode to use in validation.
NoCheck: No revocation check is performed on the certificate.
Offline: A revocation check is made using a cached certificate revocation list (CRL).
Online: A revocation check is made using an online certificate revocation list (CRL)._ 
- `[String]` **ComputerName** _A hostname or Url of the server to retreive the certificate to test._ Mandatory
- `[Int32]` **Port** _The port to connet to the remote server._ 

## Examples

### Example 1

Test the validity of the google SSL Certificate.

```powershell
Get-SSLCertificate google.com | Test-SSLCertificates
True
```
### Example 2

Tests an invalid certificates and inspect the `$error` collection for the certificate details.

```powershell
Test-SSLCertificate expired.badssl.com
Test-SSLCertificate: Certificate failed chain validation:
A certificate chain could not be built to a trusted root authority.
A required certificate is not within its validity period when verifying against the current system clock or the timestamp in the signed file.
The revocation function was unable to check revocation for the certificate.
The revocation function was unable to check revocation because the revocation server was offline.
False
PS > $error[0].TargetObject.ChainElements.Certificate.Subject
CN=badssl-fallback-unknown-subdomain-or-no-sni, O=BadSSL Fallback. Unknown subdomain or no SNI., L=San Francisco, S=California, C=US
```

## Links

- [Get-SSLCertificate](Get-SSLCertificate.md)
- [https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chain?view=net-8.0#remarks](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chain?view=net-8.0#remarks)
