# httpunitPS

<img src="httpunitps_small.png" style="float:right;width:90px;height:90px;padding:20px"/>

A PowerShell port of [httpunit](https://github.com/StackExchange/httpunit).

This is not a 100% accurate port of [httpunit](https://github.com/StackExchange/httpunit).
The goal of this module is to utilize `Net.Http.HttpClient` to more closely simulate a .Net client application.
It also provides easy access to the Windows Certificate store for client certificate authentication.

## CI

![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/cdhunt/httpunitps/powershell.yml?style=flat&logo=github)
[![Testspace pass ratio](https://img.shields.io/testspace/pass-ratio/cdhunt/cdhunt%3AhttpunitPS/main)](https://cdhunt.testspace.com/projects/67973/spaces)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/httpunitps.svg?color=%235391FE&label=PowerShellGallery&logo=powershell&style=flat)](https://www.powershellgallery.com/packages/httpunitPS)

![Build history](https://buildstats.info/github/chart/cdhunt/httpunitPS?branch=main)


## Install

`Install-Module -Name httpunitPS` or `Install-PSResource -Name httpunitPS`

![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/httpunitps?color=%235391FE&style=flat)

## Docs

[Full Docs](docs)

### Config File

[TOML](https://github.com/toml-lang/toml), YAML, JSON, and PSD1 formats are supported for the config file.

Each `plan` can have:

- `label` A label for documentation purposes.
- `url` The URL to retrieve.
- `ips` For http/https, a list of IPs to send the URL to. Default is "use DNS". Otherwise the connection is made to the IP address listed, ignoring DNS. Pass `'*'` to test all resolved addresses.
- `code` For http/https, the expected status code, default 200.
- `string` For http/https, a string we expect to find in the result.
- `timeout` An optional timeout for the test in the format `"hh:mm:ss"`. Default is 3 seconds.
- `certificate` For http/https, a path to a certificate in the Windows Store to pass as a Client Certificate. If just a Thumbprint is provided, it will look in `cert:\LocalMachine\My`.
- `tags` An optional list of tags for the test. Used for when you want to only run a subset of tests with the `-tags` flag.
- `insecureSkipVerify` Will allow testing of untrusted or self-signed certificates.
- `plan.headers` For http/https, a list of keys and values to validate the response headers.

#### A sample TOML config file

```toml
[[plan]]
  label = "google"
  url = "https://www.google.com"
  code = 200
  timeout = "0:0:10"
  [plan.headers]
  Server = "gws"
```

#### A sample YAML config file

```yaml
Plan:
- code: 200
  label: google
  timeout: "0:0:10"
  url: https://www.google.com
  tags: [run]
```

### Test-SSLCertificate

The SSLCertificate commands may be moved to a separate module in the future.

- [Get-SSLCertificate](docs/Get-SSLCertificate.md) _Get the SSL Certificate for given host._
- [Show-SSLCertificateUI](docs/Show-SSLCertificateUI.md) _Displays a dialog box with detailed information about the specified x509 certificate._
- [Test-SSLCertificate](docs/Test-SSLCertificate.md) _Test the validitiy of a given certificate._

```powershell
PS > Get-SSLCertificate expired.badssl.com | Test-SSLCertificate -ErrorVariable validation
False
```

Validation failures produces an error message.

```text
Test-SSLCertificate: Certificate failed chain validation:
A required certificate is not within its validity period when verifying against the current system clock or the timestamp in the signed file.
```

Inspect the [certificate chain](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chain) inside the ErrorRecord.

```powershell
PS > $validation.TargetObject.ChainElements.Certificate
Thumbprint                                Subject              EnhancedKeyUsageList
----------                                -------              --------------------
404BBD2F1F4CC2FDEEF13AABDD523EF61F1C71F3  CN=*.badssl.com, OU… {Server Authentication, Client Authentication}
339CDD57CFD5B141169B615FF31428782D1DA639  CN=COMODO RSA Domai… {Server Authentication, Client Authentication}
AFE5D244A8D1194230FF479FE2F897BBCD7A8CB4  CN=COMODO RSA Certi…
```
