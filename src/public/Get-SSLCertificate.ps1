function Get-SSLCertificate {
    <#
.SYNOPSIS
    Get the SSL Certificate for given host.
.DESCRIPTION
    Open an SSL connection to the given host and read the presented server certificate.
.PARAMETER ComputerName
    A hostname or Url of the server to retreive the certificate.
.PARAMETER Port
    The port to connect to the remote server.
.PARAMETER OutSslStreamVariable
    Stores SslStream connetion details from the command in the specified variable.
.NOTES
    No validation check done. This command will trust all certificates presented.
.LINK
    Invoke-HttpUnit
.LINK
    Test-SSLCertificate
.INPUTS
    String
.OUTPUTS
    System.Security.Cryptography.X509Certificates.X509Certificate2
.EXAMPLE
    Get-SSLCertificate google.com
    Thumbprint                                Subject              EnhancedKeyUsageList
    ----------                                -------              --------------------
    9B97772CC2C860B0D0663AD3ED34272FF927EDEE  CN=*.google.com      Server Authentication

    Return the certificate for google.com.
.EXAMPLE
    $cert = Get-SSLCertificate expired.badssl.com
    $cert.Verify()
    False

    Verify a server certificate. You can use Test-SSLCertificate to validate the entire certificate chain.
.EXAMPLE
    $cert = Get-SSLCertificate google.com -verbose
    VERBOSE: Converting Uri to host string
    VERBOSE: ComputerName = google.com
    VERBOSE: Cipher: Aes256 strength 256
    VERBOSE: Hash: Sha384 strength 0
    VERBOSE: Key exchange: None strength 0
    VERBOSE: Protocol: Tls13

    Write SslStream connection details to Verbose stream.
.EXAMPLE
    PS> Get-SSLCertificate -ComputerName 'google.com' -OutSslStreamVariable sslStreamValue
    Thumbprint                                Subject              EnhancedKeyUsageList
    ----------                                -------              --------------------
    5D3AD94714B07830A1BFB445F6F581AD0AC77689  CN=*.google.com      Server Authentication
    $sslStreamValue
    CipherAlgorithm      : Aes256
    CipherStrength       : 256
    HashAlgorithm        : Sha384
    HashStrength         : 0
    KeyExchangeAlgorithm : None
    KeyExchangeStrength  : 0
    SslProtocol          : Tls13

    Stores SslStream connection details in the `$sslStreamValue` variable.
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Address', 'Url')]
        [string]$ComputerName,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateRange(1, 65535)]
        [int]$Port = 443,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $OutSslStreamVariable
    )

    process {

        $uri = $null

        if ([uri]::TryCreate($ComputerName, [System.UriKind]::RelativeOrAbsolute, [ref]$uri)) {
            Write-Verbose "Converting Uri to host string"
            if (![string]::IsNullOrEmpty($uri.Host)) {
                $ComputerName = $uri.Host
                if (!$PSBoundParameters.ContainsKey('Port') -and $null -ne $uri.Port) {
                    $Port = $uri.Port
                }
            }
        }

        Write-Verbose "ComputerName = $ComputerName"

        $Certificate = $null
        $TcpClient = New-Object -TypeName System.Net.Sockets.TcpClient

        try {

            $TcpClient.Connect($ComputerName, $Port)
            $TcpStream = $TcpClient.GetStream()

            $SslStream = New-Object -TypeName System.Net.Security.SslStream -ArgumentList @($TcpStream, $true, $ServerCertificateCustomValidation_AlwaysTrust)
            try {

                $SslStream.AuthenticateAsClient($ComputerName)
                $Certificate = $SslStream.RemoteCertificate

                if ($PSBoundParameters.ContainsKey('OutSslStreamVariable')) {
                    $streamProperties = [PSCustomObject]@{
                        CipherAlgorithm      = $SslStream.CipherAlgorithm
                        CipherStrength       = $SslStream.CipherStrength
                        HashAlgorithm        = $SslStream.HashAlgorithm
                        HashStrength         = $SslStream.HashStrength
                        KeyExchangeAlgorithm = $SslStream.KeyExchangeAlgorithm
                        KeyExchangeStrength  = $SslStream.KeyExchangeStrength
                        SslProtocol          = $SslStream.SslProtocol
                    }

                    Set-Variable -Name $OutSslStreamVariable -Value $streamProperties -Scope Global
                }

                "Cipher: {0} strength {1}" -f $SslStream.CipherAlgorithm, $SslStream.CipherStrength | Write-Verbose
                "Hash: {0} strength {1}" -f $SslStream.HashAlgorithm, $SslStream.HashStrength | Write-Verbose
                "Key exchange: {0} strength {1}" -f $SslStream.KeyExchangeAlgorithm, $SslStream.KeyExchangeStrength | Write-Verbose
                "Protocol: {0}" -f $SslStream.SslProtocol | Write-Verbose

            } catch {
                $_
            } finally {
                $SslStream.Dispose()
            }
        } catch {
            $_
        } finally {
            $TcpClient.Dispose()
        }

        if ($null -ne $Certificate) {
            if ($Certificate -isnot [System.Security.Cryptography.X509Certificates.X509Certificate2]) {
                $Certificate = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $Certificate
            }

            $Certificate | Add-Member -MemberType NoteProperty -Name Host -Value $ComputerName
            Write-Output $Certificate
        }
    }
}