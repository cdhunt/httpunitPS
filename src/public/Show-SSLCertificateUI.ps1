function Show-SSLCertificateUI {
    <#
.SYNOPSIS
    Displays a dialog box with detailed information about the specified x509 certificate.
.DESCRIPTION
    Displays a dialog box with detailed information about the specified x509 certificate. The dialog box includes buttons for installing or copying the certificate.
.PARAMETER Certificate
    An X509Certificate2 certificate object.
.PARAMETER ComputerName
    A hostname or Url of the server to retreive the certificate to test.
.PARAMETER Port
    The port to connect to the remote server.
.NOTES
    PowerShell processing is blocked until the certificates dialg box is closed.
.LINK
    Get-SSLCertificate
.EXAMPLE
    Get-SSLCertificate google.com | Show-SSLCertificateUI

    Launches a certificate dialogue box with details about the google.com certificate.
#>
    [CmdletBinding(DefaultParameterSetName = 'Certificate')]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = 'Certificate')]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Host')]
        [Alias('Address', 'Url')]
        [string]$ComputerName,

        [Parameter(Position = 1, ParameterSetName = 'Host')]
        [ValidateRange(1, 65535)]
        [int]$Port
    )

    if ($PSBoundParameters.ContainsKey('ComputerName')) {
        $Certificate = Get-SSLCertificate @PSBoundParameters
    }

    [System.Security.Cryptography.X509Certificates.X509Certificate2UI]::DisplayCertificate($Certificate)
}