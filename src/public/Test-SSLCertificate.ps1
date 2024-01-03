function Test-SSLCertificate {
    <#
.SYNOPSIS
    Test the validitiy of a given certificate.
.DESCRIPTION
    Verifies the entire chain for a given certificate object or hostname. The cmdlet returns a boolean. Certificate policy validation error details are written to the pipeline as errors so you can use normal PowerShell error handling.
.PARAMETER Certificate
    An X509Certificate2 certificate object.
.PARAMETER RevocationMode
    The Revocation Mode to use in validation.
    NoCheck: No revocation check is performed on the certificate.
    Offline: A revocation check is made using a cached certificate revocation list (CRL).
    Online (Default): A revocation check is made using an online certificate revocation list (CRL).
.PARAMETER ComputerName
    A hostname or Url of the server to retreive the certificate to test.
.PARAMETER Port
    The port to connect to the remote server.
.NOTES
    Test-SSLCertificate takes into consideration the status of each element in the chain.
.LINK
    Get-SSLCertificate
.LINK
    https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509chain
.INPUTS
    String, X509Certificates
.OUTPUTS
    Bool
.EXAMPLE
    Get-SSLCertificate google.com | Test-SSLCertificate
    True

    Test the validity of the google SSL Certificate.
.EXAMPLE
    Test-SSLCertificate expired.badssl.com -ErrorVariable validation
    Test-SSLCertificate: Certificate failed chain validation:
    A required certificate is not within its validity period when verifying against the current system clock or the timestamp in the signed file.
    False
    $validation.TargetObject.ChainElements.Certificate
    Thumbprint                                Subject              EnhancedKeyUsageList
    ----------                                -------              --------------------
    404BBD2F1F4CC2FDEEF13AABDD523EF61F1C71F3  CN=*.badssl.com, OU… {Server Authentication, Client Authentication}
    339CDD57CFD5B141169B615FF31428782D1DA639  CN=COMODO RSA Domai… {Server Authentication, Client Authentication}
    AFE5D244A8D1194230FF479FE2F897BBCD7A8CB4  CN=COMODO RSA Certi…

    Tests an invalid certificates and inspect the error in variable `$validation` for the certificate details.
.EXAMPLE
    @('expired.badssl.com', 'google.com', 'https://self-signed.badssl.com' | Get-SSLCertificate | Test-SSLCertificate -ErrorVariable +testFailures

    Run multiple tests and accumulate any failures in the variable `$testFailures`.
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
            $exception = [Exception]::new(("Certificate failed chain validation for '{0}'.{1}{2}" -f $Certificate.Host, [System.Environment]::NewLine, ($Chain.ChainStatus.StatusInformation -join [System.Environment]::NewLine)))
            Write-Error -Exception $exception -Category SecurityError -ErrorId 100 -TargetObject $Chain
        }

        $buildResult | Write-Output
    }

    end {

    }
}