# Invoke-HttpUnit

This is not a 100% accurate port of httpunit. The goal of this module is to utilize Net.Http.HttpClient to more closely simulate a .Net client application. It also provides easy access to the Windows Certificate store for client certificate authentication.

## Parameters

### Parameter Set 1

- `[String]` **Url** _The URL to retrieve._ Mandatory
- `[String]` **Code** _For http/https, the expected status code, default 200._ 
- `[String]` **String** _For http/https, a string we expect to find in the result._ 
- `[Hashtable]` **Headers** _For http/https, a hashtable to validate the response headers._ 
- `[TimeSpan]` **Timeout** _A timeout for the test. Default is 3 seconds._ 
- `[X509Certificate]` **Certificate** _For http/https, specifies the client certificate that is used for a secure web request. Enter a variable that contains a certificate._ 
- `[String]` **Method** _For http/https, the HTTP method to send._ 
- `[String[]]` **IPAddress** _Provide one or more IPAddresses to target. Pass `'*'` to test all resolved addresses. Default is first resolved address._ 
- `[Switch]` **Quiet** _Do not output ErrorRecords for failed tests._ 

### Parameter Set 2

- `[String[]]` **Path** _Specifies a path to a configuration file with a list of tests. Supported types are .toml, .yml, and .psd1._ Mandatory, ValueFromPipeline
- `[String[]]` **Tag** _If specified, only runs plans that are tagged with one of the tags specified._ 
- `[Switch]` **Quiet** _Do not output ErrorRecords for failed tests._ 

## Examples

### Example 1

Run an ad-hoc test against one Url.

```powershell
Invoke-HttpUnit -Url https://www.google.com -Code 200
Label                                     Result Connected GotCode GotText GotHeaders InvalidCert TimeTotal
-----                                     ------ --------- ------- ------- ---------- ----------- ---------
https://www.google.com/ (142.250.190.132)        True      True    False   False      False       00:00:00.2840173
```
### Example 2

Run all of the tests in a given config file.

```powershell
Invoke-HttpUnit -Path .\example.toml
Label                    Result           Connected GotCode GotText GotHeaders InvalidCert TimeTotal
-----                    ------           --------- ------- ------- ---------- ----------- ---------
google (142.250.190.132)                  True      True    False   False      False       00:00:00.2064638
redirect (93.184.216.34) InvalidResult    True      False   False   False      False       00:00:00.0953043
redirect (10.11.22.33)   OperationTimeout False     False   False   False      False       00:00:03.0100917
redirect (10.99.88.77)   OperationTimeout False     False   False   False      False       00:00:03.0067049
```

## Links

- [https://github.com/StackExchange/httpunit](https://github.com/StackExchange/httpunit)
- [https://github.com/cdhunt/Import-ConfigData](https://github.com/cdhunt/Import-ConfigData)

## Notes

A `$null` Results property signifies no error and all specified test criteria passed.

You can use the common variable -OutVariable to save the test results.
Each TestResult object has a Response property with the raw response from the server.
For HTTPS tests, the TestResult object will have the ServerCertificate populated with the server certificate.
