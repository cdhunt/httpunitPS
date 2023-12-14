# Invoke-HttpUnit


This is not a 100% accurate port of httpunit. The goal of this module is to utilize Net.Http.HttpClient to more closely simulate a .Net client application. It also provides easy access to the Windows Certificate store for client certificate authentication.
## Parameters


### Parameter Set 1


- `[String]` **Url** _The URL to retrieve._  Mandatory
- `[String]` **Code** _For http/https, the expected status code, default 200._  
- `[String]` **String** _For http/https, a string we expect to find in the result._  
- `[Hashtable]` **Headers** _For http/https, a hashtable to validate the response headers._  
- `[TimeSpan]` **Timeout** _A timeout for the test. Default is 3 seconds._  
- `[X509Certificate]` **Certificate** _For http/https, specifies the client certificate that is used for a secure web request. Enter a variable that contains a certificate._  
- `[String]` **Method** _Parameter help description_  


### Parameter Set 2


- `[String]` **Path** _Specifies a path to a TOML file with a list of tests._  Mandatory, ValueFromPipeline
- `[String[]]` **Tag** _If specified, only runs plans that are tagged with one of the
tags specified._  


## Examples


### Example 1


Run an ad-hoc test against one Url.


```powershell
Invoke-HttpUnit -Url https://www.google.com -Code 200
Label       : https://www.google.com/
Result      :
Connected   : True
GotCode     : True
GotText     : False
GotRegex    : False
GotHeaders  : False
InvalidCert : False
TimeTotal   : 00:00:00.4695217
```


### Example 2


Run all of the tests in a given config file.


```powershell
Invoke-HttpUnit -Path .\example.toml
Label       : google
Result      :
Connected   : True
GotCode     : True
GotText     : False
GotRegex    : False
GotHeaders  : False
InvalidCert : False
TimeTotal   : 00:00:00.3210709
Label       : api
Result      : Exception calling "GetResult" with "0" argument(s): "No such host is known. (api.example.com:80)"
Connected   : False
GotCode     : False
GotText     : False
GotRegex    : False
GotHeaders  : False
InvalidCert : False
TimeTotal   : 00:00:00.0280893
Label       : redirect
Result      : Unexpected status code: NotFound
Connected   : True
GotCode     : False
GotText     : False
GotRegex    : False
GotHeaders  : False
InvalidCert : False
TimeTotal   : 00:00:00.1021738
```


## Links


- [https://github.com/StackExchange/httpunit](https://github.com/StackExchange/httpunit)
- [https://github.com/cdhunt/Import-ConfigData](https://github.com/cdhunt/Import-ConfigData)
