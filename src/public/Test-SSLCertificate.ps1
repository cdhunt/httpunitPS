function Test-SSLCertificate {
    <#
.SYNOPSIS
    Test the validitiy of a given certificate.
.DESCRIPTION
    Verifies the entire certificates chain from a certificate object or hostname.
.PARAMETER Certificate
    An X509Certificate2 certificate object.
.PARAMETER RevocationMode
    The Revocation Mode to use in validation.
    NoCheck: No revocation check is performed on the certificate.
    Offline: A revocation check is made using a cached certificate revocation list (CRL).
    Online: A revocation check is made using an online certificate revocation list (CRL).
.PARAMETER ComputerName
    A hostname or Url of the server to retreive the certificate to test.
.PARAMETER Port
    The port to connet to the remote server.
.NOTES
    Test-SSLCertificate takes into consideration the status of each element in the chain.
.LINK
    Get-SSLCertificate
.LINK
    https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chain?view=net-8.0#remarks
.INPUTS
    String, X509Certificates
.OUTPUTS
    Bool
.EXAMPLE
    Get-SSLCertificate google.com | Test-SSLCertificates
    True

    Test the validity of the google SSL Certificate.
.EXAMPLE
    PS > Test-SSLCertificate expired.badssl.com
    Test-SSLCertificate: Certificate failed chain validation:
    A certificate chain could not be built to a trusted root authority.
    A required certificate is not within its validity period when verifying against the current system clock or the timestamp in the signed file.
    The revocation function was unable to check revocation for the certificate.
    The revocation function was unable to check revocation because the revocation server was offline.
    False
    PS > $error[0].TargetObject.ChainElements.Certificate.Subject
    CN=badssl-fallback-unknown-subdomain-or-no-sni, O=BadSSL Fallback. Unknown subdomain or no SNI., L=San Francisco, S=California, C=US

    Tests an invalid certificates and inspect the `$error` collection for the certificate details.
#>
    [CmdletBinding(DefaultParameterSetName = 'Certificate')]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = 'Certificate')]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [Parameter(Position = 1, ParameterSetName = 'Certificate')]
        [Parameter(Position = 2, ParameterSetName = 'Host')]
        [Security.Cryptography.X509Certificates.X509RevocationMode]
        $RevocationMode = "Online",

        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Host')]
        [Alias('Address', 'Url')]
        [string]$ComputerName,

        [Parameter(Position = 1, ParameterSetName = 'Host')]
        [ValidateRange(1, 65535)]
        [int]$Port = 443
    )

    begin {
        $Chain = [System.Security.Cryptography.X509Certificates.X509Chain]::new()
        $Chain.ChainPolicy.RevocationMode = $RevocationMode
    }

    process {

        if ($PSBoundParameters.ContainsKey('ComputerName')) {
            $Certificate = Get-SSLCertificate -ComputerName $ComputerName -Port $Port
        }

        $buildResult = $Chain.Build($Certificate)

        if (! $buildResult) {
            $exception = [Exception]::new(("Certificate failed chain validation:{0}{1}" -f [System.Environment]::NewLine, ($Chain.ChainStatus.StatusInformation -join [System.Environment]::NewLine)))
            Write-Error -Exception $exception -Category SecurityError -ErrorId 100 -TargetObject $Chain
        }

        $buildResult | Write-Output
    }

    end {

    }
}