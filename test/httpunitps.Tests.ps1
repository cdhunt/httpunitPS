BeforeAll {

    Import-Module "$PSScriptRoot/../publish/httpunitPS" -Force

}

Describe 'Invoke-HttpUnit' {
    Context 'By Value' {
        It 'Should return 200 for google' {
            $result = Invoke-HttpUnit -Url https://www.google.com -Code 200

            $result.Label       | Should -Match "https://www.google.com/"
            $result.Result      | Should -BeNullOrEmpty
            $result.Connected   | Should -Be $True
            $result.GotCode     | Should -Be $True
            $result.GotText     | Should -Be $False
            $result.GotRegex    | Should -Be $False
            $result.GotHeaders  | Should -Be $False
            $result.InvalidCert | Should -Be $False
            $result.TimeTotal   | Should -BeGreaterThan ([timespan]::new(1))
        }
        It 'Should support string matching' {
            $result = Invoke-HttpUnit -Url https://example.com/ -String 'Example Domain'

            $result.Label       | Should -Match "https://example.com/"
            $result.Result      | Should -BeNullOrEmpty
            $result.Connected   | Should -Be $True
            $result.GotCode     | Should -Be $True
            $result.GotText     | Should -Be $true
            $result.GotRegex    | Should -Be $False
            $result.GotHeaders  | Should -Be $False
            $result.InvalidCert | Should -Be $False
            $result.ServerCertificate.Subject | Should -Match 'CN=www.example.org'
            $result.TimeTotal   | Should -BeGreaterThan ([timespan]::new(1))
        }

        It 'Should report a bad cert' {
            $result = Invoke-HttpUnit -Url https://expired.badssl.com/ -Quiet

            $result.Result      | Should -not -BeNullOrEmpty
            $result.Connected   | Should -Be $false
            $result.InvalidCert | Should -Be $true
            if ($PSVersionTable.PSVersion -ge [version]"7.3") {
                $result.Result.Exception.Message | Should -Be 'The remote certificate is invalid because of errors in the certificate chain: NotTimeValid'
            } else {
                $result.Result.Exception.Message | Should -Be 'The remote certificate is invalid according to the validation procedure.'
            }
            $result.ServerCertificate.Subject | Should -Be 'CN=*.badssl.com, OU=PositiveSSL Wildcard, OU=Domain Control Validated'
        }

        It 'Should not error on a bad cert with SkipVerify' {
            $result = Invoke-HttpUnit -Url https://expired.badssl.com/ -SkipVerify -Quiet

            $result.Result      | Should -BeNullOrEmpty
            $result.Connected   | Should -Be $true
            $result.InvalidCert | Should -Be $false
            $result.ServerCertificate.Subject | Should -Be 'CN=*.badssl.com, OU=PositiveSSL Wildcard, OU=Domain Control Validated'
        }

        It 'Should test a TCP port' {
            $result = Invoke-HttpUnit -Url tcp://example.com:443 -Quiet

            $result.Result | Should -BeNullOrEmpty
            $result.Connected   | Should -Be $true
        }

        It 'Should report a failed TCP test' {
            $result = Invoke-HttpUnit -Url tcp://example.com:442 -Quiet

            $result.Connected   | Should -Be $false
            $result.Result.Exception.Message | Should -Match 'Exception calling "Connect"'
        }

        It 'Should test a raw IP' {
            $result = Invoke-HttpUnit -Url https://93.184.216.34 -Quiet -SkipVerify

            $result.Result | Should -BeNullOrEmpty
            $result.Connected   | Should -Be $true
        }
    }

    Context 'By Config' {
        It 'Should return 200 for google and find header {Server = "gws"} [<type>]' -ForEach @(
            @{ config = "$PSScriptRoot/testconfig1.psd1"; type = 'PSD1' }
            @{ config = "$PSScriptRoot/testconfig1.toml"; type = 'TOML' }
        ) {
            $result = Invoke-HttpUnit -Path $config

            $result.Label       | Should -Match "google"
            $result.Result      | Should -BeNullOrEmpty
            $result.Connected   | Should -Be $True
            $result.GotCode     | Should -Be $True
            $result.GotText     | Should -Be $False
            $result.GotRegex    | Should -Be $False
            $result.GotHeaders  | Should -Be $true
            $result.InvalidCert | Should -Be $False
            $result.TimeTotal   | Should -BeGreaterThan ([timespan]::new(1))
        }

        It 'Should run for each config by pipeline' {
            $result = Get-ChildItem -Path "$PSScriptRoot/testconfig1.*" | Invoke-HttpUnit

            $result.Count | Should -Be 2
            foreach ($item in $result) {
                $item.Label       | Should -Match "google"
                $item.Result      | Should -BeNullOrEmpty
                $item.Connected   | Should -Be $True
                $item.GotCode     | Should -Be $True
                $item.GotText     | Should -Be $False
                $item.GotRegex    | Should -Be $False
                $item.GotHeaders  | Should -Be $true
                $item.InvalidCert | Should -Be $False
                $item.TimeTotal   | Should -BeGreaterThan ([timespan]::new(1))
            }
        }

        It 'Should filter by tag' {
            $result = Invoke-HttpUnit -Path "$PSScriptRoot/testconfig2.yaml" -Tag Run

            $result.Label       | Should -Match "good"
            $result.Result      | Should -BeNullOrEmpty
            $result.Connected   | Should -Be $True
            $result.GotCode     | Should -Be $True
            $result.GotText     | Should -Be $False
            $result.GotRegex    | Should -Be $False
            $result.GotHeaders  | Should -Be $False
            $result.InvalidCert | Should -Be $False
            $result.TimeTotal   | Should -BeGreaterThan ([timespan]::new(1))
        }

        It 'Should expand "*" in IPs' {
            $result = Invoke-HttpUnit -Path "$PSScriptRoot/testconfig2.yaml" -Tag run-ips

            $result.Count       | Should -BeGreaterThan 0
            $result[0].Label       | Should -Match "IPs"
            $result[0].response.RequestMessage.RequestUri.OriginalString | Should -Not -Be 'https://*'
            $result[0].response.RequestMessage.Headers.Host | Should -Be 'www.google.com'
        }
    }
    Context 'By Value by Pipeline' {
        It 'Should return 200 for google' {
            $inputObject = [PSCustomObject]@{
                Url  = 'https://www.google.com/'
                Code = 200
            }
            $result = $inputObject | Invoke-HttpUnit

            $result.Label       | Should -Match "https://www.google.com/"
            $result.Result      | Should -BeNullOrEmpty
            $result.Connected   | Should -Be $True
            $result.GotCode     | Should -Be $True
            $result.GotText     | Should -Be $False
            $result.GotRegex    | Should -Be $False
            $result.GotHeaders  | Should -Be $False
            $result.InvalidCert | Should -Be $False
            $result.TimeTotal   | Should -BeGreaterThan ([timespan]::new(1))
        }
    }

    Context 'By Value by Pipeline from CSV' {
        It 'Should return 2 results' {
            $inputObject = Import-Csv -Path "$PSScriptRoot/testpipelinevalue.csv"
            $result = $inputObject | Invoke-HttpUnit

            $result.Count       | Should -Be 2
            $result[0].Label       | Should -Match "https://www.google.com/"
            $result[0].Result      | Should -BeNullOrEmpty
            $result[0].Connected   | Should -Be $True
            $result[0].GotCode     | Should -Be $True
            $result[0].GotText     | Should -Be $False
            $result[0].GotRegex    | Should -Be $False
            $result[0].GotHeaders  | Should -Be $False
            $result[0].InvalidCert | Should -Be $False
            $result[0].TimeTotal   | Should -BeGreaterThan ([timespan]::new(1))

            $result[1].Label       | Should -Match "https://example.com/"
            $result[1].Result      | Should -BeNullOrEmpty
            $result[1].Connected   | Should -Be $True
            $result[1].GotCode     | Should -Be $True
            $result[1].GotText     | Should -Be $False
            $result[1].GotRegex    | Should -Be $False
            $result[1].GotHeaders  | Should -Be $False
            $result[1].InvalidCert | Should -Be $False
            $result[1].TimeTotal   | Should -BeGreaterThan ([timespan]::new(1))
        }
    }
}

AfterAll {
    Remove-Module httpunitPS
}