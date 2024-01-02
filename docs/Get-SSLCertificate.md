# Get-SSLCertificate

Open an SSL connection to the given host and read the presented server certificate.

## Parameters

### Parameter Set 1

- `[String]` **ComputerName** _A hostname or Url of the server to retreive the certificate._ Mandatory
- `[Int32]` **Port** _The port to connect to the remote server._ 

## Examples

### Example 1

Return the certificate for google.com.

```powershell
Get-SSLCertificate google.com
Thumbprint                                Subject              EnhancedKeyUsageList
----------                                -------              --------------------
9B97772CC2C860B0D0663AD3ED34272FF927EDEE  CN=*.google.com      Server Authentication
```
### Example 2

Verify a server certificate. You can use Test-SSLCertificate to validate the entire certificate chain.

```powershell
$cert = Get-SSLCertificate expired.badssl.com
$cert.Verify()
False
```

## Links

- [Invoke-HttpUnit](Invoke-HttpUnit.md)
- [Test-SSLCertificate](Test-SSLCertificate.md)
