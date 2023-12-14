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

    [System.Collections.Generic.List[TestCase]] Cases() {
        $cases = [System.Collections.Generic.List[TestCase]]::new()
        $planUrl = [uri]$this.URL

        <# WIP
        if ($this.IPs.Count -gt 0) {
            if ($this.IPs -contains '*') {

                $resolved = Resolve-DnsName -Name $planUrl.Host | Select-Object -ExpandProperty IPAddress
            }
        }
        #>
        $case = [TestCase]@{
            URL        = $planUrl
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

    [TestResult] TestHttp() {
        if ([string]::IsNullOrEmpty($this.Plan.Label)) {
            $this.Plan.Label = $this.URL
        }
        $result = [TestResult]::new($this.Plan.Label)
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
        $client.DefaultRequestHeaders.Host = $this.URL.Host
        $client.Timeout = $this.Plan.Timeout
        $content = [Net.Http.HttpRequestMessage]::new()
        $content.RequestUri = $this.URL
        $content.Method = [Net.Http.HttpMethod]$this.Plan.Method

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
            }
            else {
                $result.GotCode = $true
            }

            if (![string]::IsNullOrEmpty($this.ExpectText)) {
                Write-Debug ('TestHttp: ExpectText={0}' -f $this.ExpectText)

                $responseContent = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

                Write-Debug ('TestHttp: Response.Content.Length={0}' -f $responseContent.Length)

                if (!$responseContent.Contains($this.ExpectText)) {
                    $exception = [Exception]::new(("Response does not contain text {0}" -f $response.ExpectText))
                    $result.Result = [System.Management.Automation.ErrorRecord]::new($exception, "2", "InvalidResult", $response)
                }
                else {
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
                        }
                        else {
                            $headerMatchErrors += "$keyExpected=$foundValue, Expecting $expectedValue"
                        }
                    }
                    else {
                        $headerMatchErrors += "Header '$keyExpected' does not exist"
                    }
                }

                if ($headerMatchErrors.Count -gt 0) {
                    $errorMessage = $headerMatchErrors -join "; "
                    $exception = [Exception]::new(("Response headers do not match: {0}" -f $errorMessage))
                    $result.Result = [System.Management.Automation.ErrorRecord]::new($exception, "3", "InvalidResult", $response.Headers)
                }
                else {
                    $result.GotHeaders = $true
                }
            }

        }
        catch [Threading.Tasks.TaskCanceledException] {
            $exception = [Exception]::new(("Request timed out after {0:N2}s" -f $this.Plan.Timeout.TotalSeconds))
            $result.Result = [System.Management.Automation.ErrorRecord]::new($exception, "4", "OperationTimeout", $client)
        }
        catch {
            $result.Result = $_
        }
        finally {
            $result.TimeTotal = (Get-Date) - $time
        }

        return $result
    }
}

class TestResult {
    [string] $Label
    [System.Management.Automation.ErrorRecord] $Result
    hidden [object] $Response

    [bool] $Connected
    [bool] $GotCode
    [bool] $GotText
    [bool] $GotRegex
    [bool] $GotHeaders
    [bool] $InvalidCert
    [timespan] $TimeTotal

    TestResult () {}

    TestResult ([string]$label) {
        $this.Label = $label
    }
}

