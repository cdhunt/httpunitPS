# httpunitPS

A PowerShell port of [httpunit](https://github.com/StackExchange/httpunit).

This is not a 100% accurate port of [httpunit](https://github.com/StackExchange/httpunit).
The goal of this module is to utilize `Net.Http.HttpClient` to more closely simulate a .Net client application.
It also provides easy access to the Windows Certificate store for client certificate authentication.

## TOML

This configuration file is targeting compatibility with the original [httpunit file format](https://github.com/StackExchange/httpunit/tree/master#toml) but is partially implemented.

The [toml file](https://github.com/toml-lang/toml) has two sections:

- `Plan` is a list of test plans.
- `IPs` are a table of search and replace regexes. **_Not implemented_**

Each `[[plan]]` lists:

- `label =` A label for documentation purposes. It must be unique.
- `url =` The URL to retrieve.
- `ips =` For http/https, a list of IPs to send the URL to. Default is "use DNS". Otherwise the connection is made to the IP address listed, ignoring DNS. **_Not implemented_**
- `code =` For http/https, the expected status code, default 200.
- `string =` For http/https, a string we expect to find in the result.
- `regex =` For http/https, a regular expression we expect to match in the result. **_Not implemented_**
- `timeout =` An optional timeout for the test in the format `"hh:mm:ss"`. Default is 3 seconds.
- `certificate =` For http/https, a path to a certificate in the Windows Store to pass as a Client Certificate. If just a Thumbprint is provided, it will look in `cert:\LocalMachine\My`.
- `tags =` An optional set of tags for the test. Used for when you want to only run a subset of tests with the `-tags` flag **_Not implemented_**
- `insecureSkipVerify = true` Will allow testing of untrusted or self-signed certificates.
- `[plan.headers]` For http/https, a list of keys and values to validate the response headers.

## A sample config file

```toml
[[plan]]
  label = "google"
  url = "https://www.google.com"
  code = 200
  timeout = "0:0:10"
  [plan.headers]
  Server = "gws"
```

## Help

### Invoke-HttpUnit

```text
SYNTAX
    Invoke-HttpUnit [-Url] <String> [[-Code] <String>] [[-String] <String>] [[-Headers] <Hashtable>] [[-Certificate]
    <X509Certificate>] [<CommonParameters>]

    Invoke-HttpUnit [-Path] <String> [<CommonParameters>]


DESCRIPTION
    This is not a 100% accurate port of httpunit. The goal of this module is to utilize Net.Http.HttpClient to more
    closely simulate a .Net client application. It also provides easy access to the Windows Certificate store for
    client certificate authentication.


PARAMETERS
    -Path <String>
        Specifies a path to a TOML file with a list of tests.

        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       true (ByValue, ByPropertyName)
        Accept wildcard characters?  false

    -Url <String>
        The URL to retrieve.

        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Code <String>
        For http/https, the expected status code, default 200.

        Required?                    false
        Position?                    2
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -String <String>
        For http/https, a string we expect to find in the result.

        Required?                    false
        Position?                    3
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Headers <Hashtable>
        For http/https, a hashtable to validate the response headers.

        Required?                    false
        Position?                    4
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Timeout <TimeSpan>
        A timeout for the test. Default is 3 seconds.

        Required?                    false
        Position?                    5
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Certificate <X509Certificate>
        For http/https, specifies the client certificate that is used for a secure web request. Enter a variable that
        contains a certificate.

        Required?                    false
        Position?                    5
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false
```
