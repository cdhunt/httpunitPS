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
- `[Int32]` **Port** _The port to connect to the remote server._ 

## Examples

### Example 1

Test the validity of the google SSL Certificate.

```powershell
Get-SSLCertificate google.com | Test-SSLCertificates
True
```
### Example 2

Tests an invalid certificates and inspect the error in variable `$validation` for the certificate details.

```powershell
Test-SSLCertificate expired.badssl.com -ErrorVariable validation
Test-SSLCertificate: Certificate failed chain validation:
A required certificate is not within its validity period when verifying against the current system clock or the timestamp in the signed file.
False
$validation.TargetObject.ChainElements.Certificate
Thumbprint                                Subject              EnhancedKeyUsageList
----------                                -------              --------------------
404BBD2F1F4CC2FDEEF13AABDD523EF61F1C71F3  CN=*.badssl.com, OU… {Server Authentication, Client Authentication}
339CDD57CFD5B141169B615FF31428782D1DA639  CN=COMODO RSA Domai… {Server Authentication, Client Authentication}
AFE5D244A8D1194230FF479FE2F897BBCD7A8CB4  CN=COMODO RSA Certi…
```

## Links

- [Get-SSLCertificate](Get-SSLCertificate.md)
- [https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chain?view=net-8.0#remarks](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chain?view=net-8.0#remarks)
