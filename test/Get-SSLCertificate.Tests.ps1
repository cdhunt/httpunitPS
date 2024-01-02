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

    Context 'OutSslStreamVariable' {
        AfterEach {
            Remove-Variable -Name sslStreamValue -ErrorAction SilentlyContinue
        }

        It "Sets OutSslStreamVariable" {
            $cert = Get-SSLCertificate -ComputerName 'google.com' -OutSslStreamVariable sslStreamValue
            $sslStreamvalue | Should -Not -BeNullOrEmpty
            $sslStreamvalue.CipherAlgorithm | Should -BeOfType 'Security.Authentication.CipherAlgorithmType'
            $sslStreamvalue.CipherStrength | Should -BeIn @(0, 40, 56, 80, 128, 168, 192, 256)
            $sslStreamvalue.HashAlgorithm | Should -BeOfType 'Security.Authentication.HashAlgorithmType'
            $sslStreamvalue.HashStrength | Should -BeIn @(0, 128, 160)
            $sslStreamvalue.KeyExchangeAlgorithm | Should -BeOfType 'Security.Authentication.ExchangeAlgorithmType'
            $sslStreamvalue.KeyExchangeStrength | Should -BeIn @(0, 256, 512, 768, 1024, 2048)
            $sslStreamvalue.SslProtocol | Should -BeOfType 'Security.Authentication.SslProtocols'
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