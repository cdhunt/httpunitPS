function Invoke-HttpUnit {
    <#
.SYNOPSIS
    A PowerShell port of httpunit.
.DESCRIPTION
    This is not a 100% accurate port of httpunit. The goal of this module is to utilize Net.Http.HttpClient to more closely simulate a .Net client application. It also provides easy access to the Windows Certificate store for client certificate authentication.
.PARAMETER Path
    Specifies a path to a TOML file with a list of tests.
.PARAMETER Url
    The URL to retrieve.
.PARAMETER Code
    For http/https, the expected status code, default 200.
.PARAMETER String
    For http/https, a string we expect to find in the result.
.EXAMPLE
    PS > Invoke-HttpUnit -Url https://google.com -Code 200

    Result      :
    Connected   : True
    GotCode     : True
    GotText     : False
    GotRegex    : False
    InvalidCert : False
    TimeTotal   : 00:00:06.3031178
.EXAMPLE
    PS >  Invoke-HttpUnit -Path .\example.toml

    Result      :
    Connected   : True
    GotCode     : True
    GotText     : False
    GotRegex    : False
    InvalidCert : False
    TimeTotal   : 00:00:05.9053511

    Result      : Exception calling "Send" with "1" argument(s): "No such host is known. (api.example.com:80)"
    Connected   : False
    GotCode     : False
    GotText     : False
    GotRegex    : False
    InvalidCert : False
    TimeTotal   : 00:00:00.0539084

    Result      :
    Connected   : True
    GotCode     : True
    GotText     : False
    GotRegex    : False
    InvalidCert : False
    TimeTotal   : 00:00:00.1334766
.NOTES
    A $null Results property signifies no error and all specified
    test criteria passed.
.LINK
    https://github.com/StackExchange/httpunit
#>

    [CmdletBinding(DefaultParameterSetName = 'url')]
    param (
        # Specifies a path to one or more locations.
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

        # Parameter help description
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'url')]
        [Alias('Address', 'ComputerName')]
        [string]
        $Url,

        [Parameter(Position = 1,
            ParameterSetName = 'url')]
        [Alias('StatusCode')]
        [string]
        $Code,

        [Parameter(Position = 2,
            ParameterSetName = 'url')]
        [Alias('Text')]
        [string]
        $String
    )

    if ($PSBoundParameters.ContainsKey('Path')) {
        $configContent = Get-Content -Path $Path -Raw

        $configObject = [Tomlyn.Toml]::ToModel($configContent)

        foreach ($plan in $configObject['plan']) {
            $testPlan = [TestPlan]@{
                Label = $plan['label']
            }

            switch ($plan.Keys) {
                'url' { $testPlan.Url = $plan[$_] }
                'code' { $testPlan.Code = $plan[$_] }
                'string' { $testPlan.Text = $plan[$_] }
                'timeout' { $testPlan.Timeout = [timespan]$plan[$_] }
                'insecureSkipVerify' { $testPlan.InsecureSkipVerify = $plan[$_] }
            }

            foreach ($case in $testPlan.Cases()) {
                $case.Test()
            }
        }
    }
    else {
        $plan = [TestPlan]::new()
        $plan.URL = $Url

        switch ($PSBoundParameters.Keys) {
            'Code' { $plan.Code = $Code }
            'String' { $plan.Text = $String }
        }

        foreach ($case in $plan.Cases()) {
            $result = $case.Test()

            Write-Output $result
            if ($null -ne $result.Result) {
                Write-Error -ErrorRecord $result.Result
            }
        }
    }
}