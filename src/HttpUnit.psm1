class Plans {
    [System.Collections.Generic.List[TestPlan]] $Plans
}

class TestPlan {
    [string] $Label
    [string] $URL
    [string[]] $IPs
    [string[]] $Tags

    [string] $Code
    [string] $Text
    [string] $Regex
    [bool] $InsecureSkipVerify = $false
    [timespan] $Timeout = [timespan]::new(0, 0, 30)

    [System.Collections.Generic.List[TestCase]] Cases() {
        $cases = [System.Collections.Generic.List[TestCase]]::new()

        $case = [TestCase]@{
            URL  = [uri]$this.URL
            Plan = $this
        }

        if (![string]::IsNullOrEmpty($this.Code)) {
            $case.ExpectCode = [System.Net.HttpStatusCode]$this.Code
        }

        if (![string]::IsNullOrEmpty($this.Text)) {
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
            $handler.ServerCertificateCustomValidationCallback = [Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator
        }

        try {

            $response = $client.Send($content)

            #$response = Invoke-WebRequest -Uri $this.URL.ToString() -SkipCertificateCheck:$this.Plan.InsecureSkipVerify -TimeoutSec $this.Plan.Timeout.TotalSeconds

            $result.Response = $response

            $result.Connected = $true

            if ($response.StatusCode -ne $this.ExpectCode) {
                $result.Result = Write-Error -Message ("unexpected status code: {0}" -f $response.StatusCode)
            }
            else {
                $result.GotCode = $true
            }

            if (!$response.Content.ReadAsStringAsync().GetAwaiter().GetResult().Contains($this.ExpectText)) {
                $result.Result = Write-Error -Message ("response does not contain text {0}" -f $response.ExpectText)
            }
            else {
                $result.GotText = $true
            }

        }
        catch [Threading.Tasks.TaskCanceledException] {
            $result.Result = Write-Error -Message ("request timed out after {0:N2}s" -f $this.Plan.Timeout.TotalSeconds)
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

Add-Type -Path $PSScriptRoot/lib/netstandard2.0/Tomlyn.dll