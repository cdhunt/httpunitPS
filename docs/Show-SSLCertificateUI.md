# Show-SSLCertificateUI

Displays a dialog box with detailed information about the specified x509 certificate. The dialog box includes buttons for installing or copying the certificate.

## Parameters

### Parameter Set 1

- `[X509Certificate2]` **Certificate** _An X509Certificate2 certificate object._ Mandatory, ValueFromPipeline

### Parameter Set 2

- `[String]` **ComputerName** _A hostname or Url of the server to retreive the certificate to test._ Mandatory
- `[Int32]` **Port** _The port to connect to the remote server._ 

## Examples

### Example 1

Launches a certificate dialogue box with details about the google.com certificate.

```powershell
Get-SSLCertificate google.com | Show-SSLCertificateUI
```

## Links

- [Get-SSLCertificate](Get-SSLCertificate.md)

## Notes

PowerShell processing is blocked until the certificates dialg box is closed.
