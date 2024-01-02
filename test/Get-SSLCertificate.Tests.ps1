BeforeAll {

    Import-Module "$PSScriptRoot/../publish/httpunitPS" -Force

}

Describe 'Get-SSLCertificate' {
    Context 'Valid' {
        It "Returns <expected> (<name>)" -ForEach @(
            @{name = 'google.com'; expected = 'CN=*.google.com' }
            @{name = 'https://google.com'; expected = 'CN=*.google.com' }
            @{name = 'https://hsts.badssl.com/'; expected = 'CN=*.badssl.com' }
        ) {
            $cert = Get-SSLCertificate -ComputerName $name
            $cert.Subject | Should -be $expected
        }

    }

    Context 'Invalid' {
        It "Returns <expected> (<name>)" -ForEach @(
            @{name = 'expired.badssl.com'; expected = 'CN=*.badssl.com, OU=PositiveSSL Wildcard, OU=Domain Control Validated' }
            @{name = 'https://self-signed.badssl.com'; expected = 'CN=*.badssl.com, O=BadSSL, L=San Francisco, S=California, C=US' }
        ) {
            $cert = Get-SSLCertificate -ComputerName $name
            $cert.Subject | Should -be $expected
        }
    }
}

AfterAll {
    Remove-Module httpunitPS
}