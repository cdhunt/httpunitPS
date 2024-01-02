function Get-SSLCertificate {
    <#
.SYNOPSIS
    Get the SSL Certificate for given host.
.DESCRIPTION
    Open an SSL connection to the given host and read the presented server certificate.
.PARAMETER ComputerName
    A hostname or Url of the server to retreive the certificate.
.PARAMETER Port
    The port to connet to the remote server.
.NOTES
    No validation check done. This command will trust all certificates presented.
.LINK
    Invoke-HttpUnit
.INPUTS
    String
.OUTPUTS
    System.Security.Cryptography.X509Certificates.X509Certificate2
.EXAMPLE
    Get-SSLCertificate google.com
    Thumbprint                                Subject              EnhancedKeyUsageList
    ----------                                -------              --------------------
    9B97772CC2C860B0D0663AD3ED34272FF927EDEE  CN=*.google.com      Server Authentication

    Return the certificate for google.com
.EXAMPLE
    $cert = Get-SSLCertificate expired.badssl.com
    $cert.Verify()
    False

    Verify a server certificates
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [Alias('Address', 'Url')]
        [string]$ComputerName,

        [Parameter(Position = 1)]
        [ValidateRange(1, 65535)]
        [int]$Port = 443

    )

    $uri = $null

    if ([uri]::TryCreate($ComputerName, [System.UriKind]::RelativeOrAbsolute, [ref]$uri)) {
        Write-Verbose "Converting Uri to host string"
        if (![string]::IsNullOrEmpty($uri.Host)) {
            $ComputerName = $uri.Host
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

        Write-Output $Certificate
    }
}