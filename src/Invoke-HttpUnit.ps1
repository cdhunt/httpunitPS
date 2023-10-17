function Invoke-HttpUnit {
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