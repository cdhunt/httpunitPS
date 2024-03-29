function Invoke-HttpUnit {
<#
.SYNOPSIS
    A PowerShell port of httpunit.
.DESCRIPTION
    This is not a 100% accurate port of httpunit. The goal of this module is to utilize Net.Http.HttpClient to more closely simulate a .Net client application. It also provides easy access to the Windows Certificate store for client certificate authentication.
.PARAMETER Path
    Specifies a path to a configuration file with a list of tests. Supported types are .toml, .yml, json, and .psd1.
.PARAMETER Tag
    If specified, only runs plans that are tagged with one of the tags specified.
.PARAMETER Url
    The URL to retrieve.
.PARAMETER Code
    For http/https, the expected status code, default 200.
.PARAMETER String
    For http/https, a string we expect to find in the result.
.PARAMETER Headers
    For http/https, a hashtable to validate the response headers.
.PARAMETER Timeout
    A timeout for the test. Default is 3 seconds.
.PARAMETER Certificate
    For http/https, specifies the client certificate that is used for a secure web request. Enter a variable that contains a certificate.
.PARAMETER Method
    For http/https, the HTTP method to send.
.PARAMETER IPAddress
    Provide one or more IPAddresses to target. Pass `'*'` to test all resolved addresses. Default is first resolved address.
.PARAMETER SkipVerify
    Allow testing of untrusted or self-signed certificates
.PARAMETER Quiet
    Do not output ErrorRecords for failed tests.
.EXAMPLE
    PS > Invoke-HttpUnit -Url https://www.google.com -Code 200
    Label                                     Result Connected GotCode GotText GotHeaders InvalidCert TimeTotal
    -----                                     ------ --------- ------- ------- ---------- ----------- ---------
    https://www.google.com/ (142.250.190.132)        True      True    False   False      False       00:00:00.2840173

    Run an ad-hoc test against one Url.

    .EXAMPLE
    PS >   Invoke-HttpUnit -Path .\example.toml
    Label                    Result           Connected GotCode GotText GotHeaders InvalidCert TimeTotal
    -----                    ------           --------- ------- ------- ---------- ----------- ---------
    google (142.250.190.132)                  True      True    False   False      False       00:00:00.2064638
    redirect (93.184.216.34) InvalidResult    True      False   False   False      False       00:00:00.0953043
    redirect (10.11.22.33)   OperationTimeout False     False   False   False      False       00:00:03.0100917
    redirect (10.99.88.77)   OperationTimeout False     False   False   False      False       00:00:03.0067049

    Run all of the tests in a given config file.
.NOTES
    A `$null` Results property signifies no error and all specified test criteria passed.

    You can use the common variable _OutVariable_ to save the test results.
    Each TestResult object has a Response property with the raw response from the server.
    For HTTPS tests, the TestResult object will have the ServerCertificate populated with the certificate presented by the server.
.LINK
    https://github.com/StackExchange/httpunit
.LINK
    https://github.com/cdhunt/Import-ConfigData
#>

    [CmdletBinding(DefaultParameterSetName = 'url')]
    [Alias('httpunit', 'Test-Http', 'ihu')]
    param (
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'config-file',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path,

        [Parameter(Position = 1,
            ParameterSetName = 'config-file')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Tag,

        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'url',
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Address', 'ComputerName')]
        [string]
        $Url,

        [Parameter(Position = 1,
            ParameterSetName = 'url',
            ValueFromPipelineByPropertyName = $true)]
        [Alias('StatusCode')]
        [string]
        $Code,

        [Parameter(Position = 2,
            ParameterSetName = 'url',
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Text')]
        [string]
        $String,

        [Parameter(Position = 3,
            ParameterSetName = 'url',
            ValueFromPipelineByPropertyName = $true)]
        [hashtable]
        $Headers,

        [Parameter(Position = 4,
            ParameterSetName = 'url',
            ValueFromPipelineByPropertyName = $true)]
        [timespan]
        $Timeout,

        [Parameter(Position = 5,
            ParameterSetName = 'url',
            ValueFromPipelineByPropertyName = $true)]
        [X509Certificate]
        $Certificate,

        [Parameter(Position = 6,
            ParameterSetName = 'url',
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Connect', 'Delete', 'Get', 'Head', 'Options', 'Patch', 'Post', 'Put', 'Trace')]
        [String]
        $Method,

        [Parameter(Position = 7,
            ParameterSetName = 'url',
            ValueFromPipelineByPropertyName = $true)]
        [String[]]
        $IPAddress,

        [Parameter()]
        [Alias('InsecureSkipVerify')]
        [switch]
        $SkipVerify,

        [Parameter()]
        [Switch]
        $Quiet
    )

    process {

        if ($PSBoundParameters.ContainsKey('Path')) {
            foreach ($p in $Path) {
                Write-Debug "Running checks defined in '$p'"


                $configObject = Import-ConfigData -Path $p

                foreach ($plan in $configObject['plan']) {
                    $testPlan = [TestPlan]@{
                        Label = $plan['label']
                    }

                    switch ($plan.Keys) {
                        'label' { $testPlan.Label = $plan[$_] }
                        'url' { $testPlan.Url = $plan[$_] }
                        'method' { $testPlan.Method = $plan[$_] }
                        'code' { $testPlan.Code = $plan[$_] }
                        'string' { $testPlan.Text = $plan[$_] }
                        'timeout' { $testPlan.Timeout = [timespan]$plan[$_] }
                        'tags' { $testPlan.Tags = $plan[$_] }
                        'headers' { $testPlan.Headers = $plan[$_] }
                        'ips' { $testPlan.IPs = $plan[$_] }
                        'certificate' {
                            $value = $plan[$_]
                            if ($value -like 'cert:\*') {
                                $testPlan.ClientCertificate = Get-Item $value
                            } else {
                                $testPlan.ClientCertificate = (Get-Item "Cert:\LocalMachine\My\$value")
                            }
                        }
                        'insecureSkipVerify' { $testPlan.InsecureSkipVerify = $plan[$_] }
                    }

                    # Filter tests
                    if ($PSBoundParameters.ContainsKey('Tag')) {
                        $found = $false
                        foreach ($t in $Tag) {
                            if ($testPlan.Tags -contains $t) { $found = $true }
                        }
                        if (!$found) {
                            $testTags = $testPlan.Tags -join ', '
                            $filterTags = $Tag -join ', '
                            Write-Debug "Specified tags ($filterTags) do not match defined tags ($testTags)"
                            Continue
                        }
                    }

                    foreach ($case in $testPlan.Cases()) {
                        $case.Test()
                    }
                }
            }
        } else {
            $plan = [TestPlan]::new()
            $plan.URL = $Url

            switch ($PSBoundParameters.Keys) {
                'Code' { $plan.Code = $Code }
                'String' { $plan.Text = $String }
                'Headers' { $plan.Headers = $Headers }
                'Timeout' { $plan.Timeout = $Timeout }
                'Certificate' { $plan.ClientCertificate = $Certificate }
                'Method' { $plan.Method = $Method }
                'IPAddress' { $plan.IPs = $IPAddress }
            }

            if ($SkipVerify) { $plan.insecureSkipVerify = $true }

            foreach ($case in $plan.Cases()) {
                $result = $case.Test()

                Write-Output $result
                if ($null -ne $result.Result -and !$Quiet) {
                    Write-Error -ErrorRecord $result.Result
                }
            }
        }
    }
}