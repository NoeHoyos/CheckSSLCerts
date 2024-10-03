param(
    [string]$InputFile,          # File with the list of URLs
    [switch]$OutputCsv           # Optional switch to output results in CSV format
)

function Get-SSLCertificateExpiration {
    param (
        [string]$Url,
        [int]$WarningDays = 30
    )

    try {
        # Ensure URL starts with "https://"
        if (-not $Url.StartsWith("https://")) {
            Write-Host "ERROR: URL '$Url' does not use HTTPS. Skipping..." -ForegroundColor Red
            return $null
        }

        # Parse the URL to extract the webserver and port
        $uri = [System.Uri]$Url
        $webserver = $uri.Host
        $port = if ($uri.Port -eq -1) { 443 } else { $uri.Port }

        # Create a TCP connection to the server on the specified port
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($webserver, $port)

        # Get the SSL stream
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false,
            { param($sender, $certificate, $chain, $sslPolicyErrors) return $true })

        # Authenticate as client to get the certificate
        $sslStream.AuthenticateAsClient($webserver)

        # Get certificate details
        $cert = $sslStream.RemoteCertificate
        $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $cert
        $expirationDate = $cert2.NotAfter

        # Calculate remaining days before expiration and recommended time to renew
        $daysUntilExpiration = ($expirationDate - (Get-Date)).Days
        $recommendedRenewalDate = $expirationDate.AddDays(-30)

        # Prepare the result as an object
        [PSCustomObject]@{
            URL = $Url
            ExpirationDate = $expirationDate
            DaysUntilExpiration = $daysUntilExpiration
            RecommendedRenewalDate = $recommendedRenewalDate
        }

        # Clean up
        $sslStream.Close()
        $tcpClient.Close()
    }
    catch {
        Write-Host "ERROR: Could not retrieve SSL certificate for $Url. $_" -ForegroundColor Red
        return $null
    }
}

# Read URLs from input file
if (Test-Path $InputFile) {
    $urls = Get-Content -Path $InputFile | Where-Object { 
        $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#")
    }

    # Collect results for all URLs
    $results = foreach ($url in $urls) {
        Write-Host "Checking SSL certificate expiration for $url..."
        Get-SSLCertificateExpiration -Url $url
    }

    # Filter out null results
    $validResults = $results | Where-Object { $_ -ne $null }

    if ($validResults.Count -gt 0) {
        if ($OutputCsv) {
            # Output results in CSV format
            $validResults | Export-Csv -Path "SSL_Certificate_Results.csv" -NoTypeInformation
            Write-Host "Results have been saved to SSL_Certificate_Results.csv" -ForegroundColor Green
        } else {
            # Output results in table format with the new "Recommended Time to Renew" column
            $validResults | Format-Table -Property URL, ExpirationDate, DaysUntilExpiration, RecommendedRenewalDate -AutoSize
        }
    } else {
        Write-Host "No valid results to display." -ForegroundColor Yellow
    }
} else {
    Write-Host "ERROR: Input file $InputFile not found." -ForegroundColor Red
}
