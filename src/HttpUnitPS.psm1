class Plans {
    [System.Collections.Generic.List[TestPlan]] $Plans
}

class TestPlan {
    [string] $Label
    [string] $URL
    [string[]] $IPs
    [string[]] $Tags

    [string] $Code = "200"
    [string] $Text
    [string] $Regex
    [bool] $InsecureSkipVerify = $false
    [timespan] $Timeout = [timespan]::new(0, 0, 3)

    [System.Collections.Generic.List[TestCase]] Cases() {
        $cases = [System.Collections.Generic.List[TestCase]]::new()

        $case = [TestCase]@{
            URL        = [uri]$this.URL
            Plan       = $this
            ExpectCode = [System.Net.HttpStatusCode]$this.Code
        }

        if (![string]::IsNullOrEmpty($this.Text)) {
            Write-Debug ('Adding simple string matching test case. "{0}"' -f $this.Text)
            $case.ExpectText = $this.Text
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

    hidden [version] $_psVersion = $PSVersionTable.PSVersion

    [TestResult] Test() {
        switch ($this.URL.Scheme) {
            http { return $this.TestHttp() }
            https { return $this.TestHttp() }
        }

        $noTest = [TestResult]::new()
        $noTest.Result = Write-Error -Message ("no test function implemented for URL Scheme '{0}'" -f $this.URL.Scheme )
        return $noTest
    }

    [TestResult] TestHttp() {
        $result = [TestResult]::new()
        $time = Get-Date

        Write-Debug ('TestHttp: Url={0} ExpectCode={1}' -f $this.URL.AbsoluteUri, $this.ExpectCode)

        if ($this._psVersion -le [version]"5.1") {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

            Add-Type -AssemblyName System.Net.Http
        }

        $handler = [Net.Http.HttpClientHandler]::new()
        $client = [Net.Http.HttpClient]::new($handler)
        $client.DefaultRequestHeaders.Host = $this.URL.Host
        $client.Timeout = $this.Plan.Timeout
        $content = [Net.Http.HttpRequestMessage]::new()
        $content.RequestUri = $this.URL

        if ($this.Plan.InsecureSkipVerify) {
            Write-Debug ('TestHttp: ValidateSSL={0}' -f $this.Plan.InsecureSkipVerify)
            $handler.ServerCertificateCustomValidationCallback = [Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator
        }

        try {

            $response = $client.Send($content)

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
                $responseContent = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                Write-Debug ('TestHttp: Response.Content.Length={0} ExpectText={0}' -f $responseContent.Length, $this.ExpectText)
                if (!$responseContent.Contains($this.ExpectText)) {
                    $exception = [Exception]::new(("Response does not contain text {0}" -f $response.ExpectText))
                    $result.Result = [System.Management.Automation.ErrorRecord]::new($exception, "2", "InvalidResult", $response)
                }
                else {
                    $result.GotText = $true
                }
            }

        }
        catch [Threading.Tasks.TaskCanceledException] {
            $result.Result = Write-Error -Message
            $exception = [Exception]::new(("Request timed out after {0:N2}s" -f $this.Plan.Timeout.TotalSeconds))
            $result.Result = [System.Management.Automation.ErrorRecord]::new($exception, "3", "OperationTimeout", $client)
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
    [System.Management.Automation.ErrorRecord] $Result
    hidden [object] $Response

    [bool] $Connected
    [bool] $GotCode
    [bool] $GotText
    [bool] $GotRegex
    [bool] $InvalidCert
    [timespan] $TimeTotal
}

Add-Type -Path "$PSScriptRoot/lib/netstandard2.0/Tomlyn.dll"

. "$PSScriptRoot/Invoke-HttpUnit.ps1"