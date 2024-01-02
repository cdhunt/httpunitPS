BeforeAll {

    Import-Module "$PSScriptRoot/../publish/httpunitPS" -Force

}

Describe 'Test-SSLCertificate' {
    Context 'Valid (Certificate)' {
        It "Returns True (<name>)" -ForEach @(
            @{name = 'google.com' }
            @{name = 'https://google.com' }
            @{name = 'https://hsts.badssl.com/' }
        ) {
            $result = Get-SSLCertificate -ComputerName $name | Test-SSLCertificate
            $result | Should -BeTrue
        }
    }

    Context 'Valid (Hostname)' {
        It "Returns True (<name>)" -ForEach @(
            @{name = 'google.com' }
            @{name = 'https://google.com' }
            @{name = 'https://hsts.badssl.com/' }
        ) {
            $result = Test-SSLCertificate -ComputerName $name
            $result | Should -BeTrue
        }

        It "Returns True (https://tls-v1-2.badssl.com:1012/)" {
            $result = Test-SSLCertificate -ComputerName 'https://tls-v1-2.badssl.com' -Port 1012
            $result | Should -BeTrue
        }
    }

    Context 'Invalid' {
        It "Returns False (expired.badssl.com)" {
            $result = Get-SSLCertificate -ComputerName 'expired.badssl.com' | Test-SSLCertificate -ErrorAction SilentlyContinue
            $result | Should -Not -BeTrue
            $error[0].TargetObject.ChainElements.Certificate.Subject | Should -Contain 'CN=*.badssl.com, OU=PositiveSSL Wildcard, OU=Domain Control Validated'
            $error[0].TargetObject.ChainStatus.Status | Should -Be 'NotTimeValid'
        }

        It "Returns False (https://self-signed.badssl.com)" {
            $result = Get-SSLCertificate -ComputerName 'https://self-signed.badssl.com' | Test-SSLCertificate -ErrorAction SilentlyContinue
            $result | Should -Not -BeTrue
            $error[0].TargetObject.ChainElements.Certificate.Subject | Should -Contain 'CN=*.badssl.com, O=BadSSL, L=San Francisco, S=California, C=US'
            $error[0].TargetObject.ChainStatus.Status | Should -Be 'UntrustedRoot'
        }
    }
}

AfterAll {
    Remove-Module httpunitPS
}