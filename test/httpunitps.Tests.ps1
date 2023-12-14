BeforeAll {

    Import-Module "$PSScriptRoot/../publish/httpunitps" -Force

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
    }
    Context 'By Config' {
        It 'Should return 200 for google and find header {Server = "gws"}' {
            $result = Invoke-HttpUnit -Path "$PSScriptRoot/testconfig1.toml"

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
    }
}

AfterAll {
    Remove-Module httpunitps
}