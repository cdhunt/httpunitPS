class Plans {
    [System.Collections.Generic.List[TestPlan]] $Plans
}

class TestPlan {
    [string] $Label
    [string] $URL
    [string] $Method = "Get"
    [string[]] $IPs
    [string[]] $Tags

    [string] $Code = "200"
    [string] $Text
    [string] $Regex
    [hashtable] $Headers
    [bool] $InsecureSkipVerify = $false
    [X509Certificate] $ClientCertificate
    [timespan] $Timeout = [timespan]::new(0, 0, 3)

    [string[]] ResolveIPs ([bool]$All) {
        $planUrl = [uri]$this.URL
        $hostName = $planUrl.DnsSafeHost

        $addressList = $null
        $isIp = [ipaddress]::TryParse($hostName, [ref]$addressList)
        if (!$isip) {
            $addressList = [Net.Dns]::GetHostEntry($hostName) |
            Select-Object -ExpandProperty AddressList |
            Where-Object AddressFamily -eq 'InterNetwork' |
            Select-Object -ExpandProperty IPAddressToString
        }
        if (!$All) {
            return $addressList | Select-Object -First 1
        }

        return $addressList
    }

    [string[]] ExpandIpList () {
        $expandedIPList = @()

        if ($this.IPs.Count -gt 0) {

            $this.IPs | ForEach-Object {
                if ($_ -eq '*') {
                    $expandedIPList += $this.ResolveIPs($true)
                } else {
                    $ip = [ipaddress]'0.0.0.0'
                    $isIp = [ipaddress]::TryParse($_, [ref]$ip)
                    if ($isIp) {
                        $expandedIPList += $ip.ToString()
                    } else {
                        Write-Warning "'$_' is not a valid IPAddress"
                    }
                }
            }
        } else {
            $expandedIPList += $this.ResolveIPs($false)
        }

        return $expandedIPList
    }

    [System.Collections.Generic.List[TestCase]] Cases() {
        $cases = [System.Collections.Generic.List[TestCase]]::new()
        $planUrl = [uri]$this.URL

        foreach ($item in $this.ExpandIpList()) {
            Write-Debug ('Adding test case for "{0}"' -f $item)
            $case = [TestCase]@{
                URL        = $planUrl
                IP         = $item
                Plan       = $this
                ExpectCode = [System.Net.HttpStatusCode]$this.Code
            }

            if (![string]::IsNullOrEmpty($this.Text)) {
                Write-Debug ('Adding simple string matching test case. "{0}"' -f $this.Text)
                $case.ExpectText = $this.Text
            }

            if ($null -ne $this.Headers) {
                Write-Debug ('Adding headers test case. Checking for "{0}" headers' -f $this.Headers.Count)
                $case.ExpectHeaders = $this.Headers
            }

            $cases.Add($case)
        }

        return $cases
    }
}

class TestCase {
    [uri] $URL
    [ipaddress] $IP
    [int] $Port

    [TestPlan] $Plan

    [System.Net.HttpStatusCode] $ExpectCode
    [string] $ExpectText
    [regex] $ExpectRegex
    [hashtable] $ExpectHeaders

    hidden [version] $_psVersion = $PSVersionTable.PSVersion

    [TestResult] Test() {
        switch ($this.URL.Scheme) {
            http { return $this.TestHttp() }
            https { return $this.TestHttp() }
            tcp { return $this.TestTcp() }
            file {
                $fileTest = [TestResult]::new()
                $exception = [Exception]::new(("URL Scheme '{0}' is not supported. Did you mean to use the -Path parameter?" -f $this.URL.Scheme ))
                $fileTest.Result = [System.Management.Automation.ErrorRecord]::new($exception, "100", "InvalidData", $this.URL)
                return $fileTest
            }
        }


        $noTest = [TestResult]::new()
        $exception = [Exception]::new(("no test function implemented for URL Scheme '{0}'" -f $this.URL.Scheme ))
        $noTest.Result = [System.Management.Automation.ErrorRecord]::new($exception, "100", "InvalidData", $this.URL)
        return $noTest
    }

    [TestResult] TestTcp() {
        if ([string]::IsNullOrEmpty($this.Plan.Label)) {
            $this.Plan.Label = $this.URL
        }
        $result = [TestResult]::new($this.Plan.Label)
        $result.Connected = $true
        $time = Get-Date

        $testName = $this.IP
        $testPort = $this.URL.Port

        $result.Label = '{0} ({1})' -f $result.Label, $testName

        $socket = [Net.Sockets.Socket]::new([Net.Sockets.AddressFamily]::InterNetwork, [Net.Sockets.SocketType]::Stream, [Net.Sockets.ProtocolType]::Tcp )

        try {
            $socket.Connect($testName, $testPort)
            $socket.Shutdown([Net.Sockets.SocketShutdown]::Both)
        } catch {
            $result.Connected = $false
            $result.Result = [System.Management.Automation.ErrorRecord]::new($_.Exception, "10", "ConnectionError", $this.URL)
        } finally {
            $socket.Close()
        }

        $result.TimeTotal = (Get-Date) - $time
        return $result
    }

    [TestResult] TestHttp() {
        if ([string]::IsNullOrEmpty($this.Plan.Label)) {
            $this.Plan.Label = $this.URL
        }
        $result = [TestResult]::new($this.Plan.Label)

        $result.Label = '{0} ({1})' -f $result.Label, $this.IP
        $time = Get-Date

        Write-Debug ('TestHttp: Url={0} ExpectCode={1}' -f $this.URL.AbsoluteUri, $this.ExpectCode)

        if ($this._psVersion -lt [version]"6.0") {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
        }

        $handler = [Net.Http.HttpClientHandler]::new()

        if ($null -ne $this.Plan.ClientCertificate) {
            Write-Debug ('TestHttp: ClientCertificate={0}' -f $this.Plan.ClientCertificate.Thumbprint)
            $handler.ClientCertificates.Add($this.Plan.ClientCertificate)
        }

        $client = [Net.Http.HttpClient]::new($handler)
        if ($this.URL.Host -ne $this.IP) {
            $client.DefaultRequestHeaders.Host = $this.URL.Host
        }

        $client.Timeout = $this.Plan.Timeout


        $testUri = $this.URL.OriginalString -replace $this.URL.Host, $this.IP.ToString()
        $content = [Net.Http.HttpRequestMessage]::new($this.Plan.Method, [Uri]$testUri)

        if ($this.Plan.InsecureSkipVerify) {
            Write-Debug ('TestHttp: ValidateSSL={0}' -f $this.Plan.InsecureSkipVerify)
            $handler.ServerCertificateCustomValidationCallback = [Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator
        }

        try {

            Write-Debug "Sending request"
            $response = $client.SendAsync($content).GetAwaiter().GetResult()
            Write-Debug "Got response"
            $result.Response = $response
            $result.Connected = $true

            if ($response.StatusCode -ne $this.ExpectCode) {
                $exception = [Exception]::new(("Unexpected status code: {0}" -f $response.StatusCode))
                $result.Result = [System.Management.Automation.ErrorRecord]::new($exception, "1", "InvalidResult", $response)
            } else {
                $result.GotCode = $true
            }

            if (![string]::IsNullOrEmpty($this.ExpectText)) {
                Write-Debug ('TestHttp: ExpectText={0}' -f $this.ExpectText)

                $responseContent = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

                Write-Debug ('TestHttp: Response.Content.Length={0}' -f $responseContent.Length)

                if (!$responseContent.Contains($this.ExpectText)) {
                    $exception = [Exception]::new(("Response does not contain text {0}" -f $response.ExpectText))
                    $result.Result = [System.Management.Automation.ErrorRecord]::new($exception, "2", "InvalidResult", $response)
                } else {
                    $result.GotText = $true
                }
            }

            if ($null -ne $this.ExpectHeaders) {
                Write-Debug ('TestHttp: Headers=@({0})' -f ($this.ExpectHeaders.Keys -join ', '))
                $headerMatchErrors = @()

                foreach ($keyExpected in $this.ExpectHeaders.Keys) {

                    $expectedValue = $this.ExpectHeaders[$keyExpected]

                    if ($response.Headers.Key -contains $keyExpected) {

                        $foundValue = $response.Headers.Where({ $_.Key -eq $keyExpected }).Value

                        if ($foundValue -like $expectedValue) {
                            continue
                        } else {
                            $headerMatchErrors += "$keyExpected=$foundValue, Expecting $expectedValue"
                        }
                    } else {
                        $headerMatchErrors += "Header '$keyExpected' does not exist"
                    }
                }

                if ($headerMatchErrors.Count -gt 0) {
                    $errorMessage = $headerMatchErrors -join "; "
                    $exception = [Exception]::new(("Response headers do not match: {0}" -f $errorMessage))
                    $result.Result = [System.Management.Automation.ErrorRecord]::new($exception, "3", "InvalidResult", $response.Headers)
                } else {
                    $result.GotHeaders = $true
                }
            }

        } catch [System.Threading.Tasks.TaskCanceledException] {
            $exception = [Exception]::new(("Request timed out after {0:N2}s" -f $this.Plan.Timeout.TotalSeconds))
            $result.Result = [System.Management.Automation.ErrorRecord]::new($exception, "4", "OperationTimeout", $client)
        } catch {
            if ($_.Exception.GetBaseException().Message -like 'The remote certificate is invalid*') {
                $result.InvalidCert = $true
            }

            $result.Result = [System.Management.Automation.ErrorRecord]::new($_.Exception.GetBaseException(), "5", "ConnectionError", $content)
        } finally {
            $result.TimeTotal = (Get-Date) - $time

            if ($this.URL.Scheme -eq 'https') {
                $result.ServerCertificate = Get-SSLCertificate -ComputerName $this.URL.DnsSafeHost -Port $this.URL.Port
            }
        }

        return $result
    }
}

class TestResult {
    [string] $Label
    [System.Management.Automation.ErrorRecord] $Result
    [object] $Response

    [bool] $Connected
    [bool] $GotCode
    [bool] $GotText
    [bool] $GotRegex
    [bool] $GotHeaders
    [bool] $InvalidCert
    [Security.Cryptography.X509Certificates.X509Certificate2] $ServerCertificate
    [timespan] $TimeTotal

    TestResult () {}

    TestResult ([string]$label) {
        $this.Label = $label
    }
}

# https://learn.microsoft.com/en-us/dotnet/api/system.net.security.remotecertificatevalidationcallback?view=net-8.0
$ServerCertificateCustomValidation_AlwaysTrust = { param($senderObject, $cert, $chain, $errors) return $true }
