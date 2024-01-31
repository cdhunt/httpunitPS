function Invoke-HttpUnit {
<#
.SYNOPSIS
    A PowerShell port of httpunit.
.DESCRIPTION
    This is not a 100% accurate port of httpunit. The goal of this module is to utilize Net.Http.HttpClient to more closely simulate a .Net client application. It also provides easy access to the Windows Certificate store for client certificate authentication.
.PARAMETER Path
    Specifies a path to a configuration file with a list of tests. Supported types are .toml, .yml, and .psd1.
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
.PARAMETER Quiet
    Do not output ErrorRecords for failed tests.
.EXAMPLE
    PS > Invoke-HttpUnit -Url https://www.google.com -Code 200
    Label       : https://www.google.com/
    Result      :
    Connected   : True
    GotCode     : True
    GotText     : False
    GotRegex    : False
    GotHeaders  : False
    InvalidCert : False
    TimeTotal   : 00:00:00.4695217

    Run an ad-hoc test against one Url.

    .EXAMPLE
    PS >   Invoke-HttpUnit -Path .\example.toml
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

    Run all of the tests in a given config file.
.NOTES
    A `$null` Results property signifies no error and all specified test criteria passed.

    You can use the common variable -OutVariable to save the test results. Each TestResult object has a hidden Response property with the raw response from the server.
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
        [string]
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
        [Switch]
        $Quiet
    )

    if ($PSBoundParameters.ContainsKey('Path')) {
        Write-Debug "Running checks defined in '$Path'"


        $configObject = Import-ConfigData -Path $Path

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
                'certficate' {
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

        foreach ($case in $plan.Cases()) {
            $result = $case.Test()

            Write-Output $result
            if ($null -ne $result.Result -and !$Quiet) {
                Write-Error -ErrorRecord $result.Result
            }
        }
    }
}