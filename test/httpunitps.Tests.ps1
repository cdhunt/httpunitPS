BeforeAll {

    Import-Module "$PSScriptRoot/../publish/httpunitPS" -Force

}

Describe 'Invoke-HttpUnit' {
    Context 'By Value' {
        It 'Should return 200 for google' {
            $result = Invoke-HttpUnit -Url https://www.google.com -Code 200

            $result.Label       | Should -Be "https://www.google.com/"
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

            $result.Label       | Should -Be "https://example.com/"
            $result.Result      | Should -BeNullOrEmpty
            $result.Connected   | Should -Be $True
            $result.GotCode     | Should -Be $True
            $result.GotText     | Should -Be $true
            $result.GotRegex    | Should -Be $False
            $result.GotHeaders  | Should -Be $False
            $result.InvalidCert | Should -Be $False
            $result.TimeTotal   | Should -BeGreaterThan ([timespan]::new(1))
        }

        It 'Should report a bad cert' {
            $result = Invoke-HttpUnit -Url https://expired.badssl.com/ -Quiet

            $result.Result      | Should -not -BeNullOrEmpty
            $result.Connected   | Should -Be $false
            $result.InvalidCert | Should -Be $true
            if ($PSVersionTable.PSVersion -ge [version]"7.3") {
                $result.Result.Exception.Message | Should -Be 'The remote certificate is invalid because of errors in the certificate chain: NotTimeValid'
            }
            else {
                $result.Result.Exception.Message | Should -Be 'The remote certificate is invalid according to the validation procedure.'
            }
        }
    }
    Context 'By Config' {
        It 'Should return 200 for google and find header {Server = "gws"} [<type>]' -ForEach @(
            @{ config = "$PSScriptRoot/testconfig1.psd1"; type = 'PSD1' }
            @{ config = "$PSScriptRoot/testconfig1.toml"; type = 'TOML' }
        ) {
            $result = Invoke-HttpUnit -Path $config

            $result.Label       | Should -BeExactly "google"
            $result.Result      | Should -BeNullOrEmpty
            $result.Connected   | Should -Be $True
            $result.GotCode     | Should -Be $True
            $result.GotText     | Should -Be $False
            $result.GotRegex    | Should -Be $False
            $result.GotHeaders  | Should -Be $true
            $result.InvalidCert | Should -Be $False
            $result.TimeTotal   | Should -BeGreaterThan ([timespan]::new(1))
        }

        It 'Should filter by tag' {
            $result = Invoke-HttpUnit -Path "$PSScriptRoot/testconfig2.yaml" -Tag Run

            $result.Label       | Should -BeExactly "good"
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

            $result.Count       | Should -BeGreaterThan 2
            $result[0].Label       | Should -BeExactly "IPs"
        }
    }
    Context 'By Value by Pipeline' {
        It 'Should return 200 for google' {
            $inputObject = [PSCustomObject]@{
                Url  = 'https://www.google.com/'
                Code = 200
            }
            $result = $inputObject | Invoke-HttpUnit

            $result.Label       | Should -Be "https://www.google.com/"
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
}

AfterAll {
    Remove-Module httpunitPS
}