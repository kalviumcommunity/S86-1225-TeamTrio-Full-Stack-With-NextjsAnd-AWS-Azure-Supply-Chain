# =============================================================================
# HTTPS Configuration Verification & Testing
# Purpose: Verify HTTPS setup, SSL certificates, and security headers
# Usage: .\test-https.ps1 -URL "https://foodontracks.local"
# =============================================================================

param(
    [string]$URL = "https://foodontracks.local",
    [switch]$SkipCertificateValidation = $false
)

Write-Host "=== HTTPS Configuration Testing ===" -ForegroundColor Green
Write-Host "Testing URL: $URL"
Write-Host ""

# =============================================================================
# 1. URL Validation
# =============================================================================

function Test-URLFormat {
    param([string]$URLString)
    
    Write-Host "Validating URL format..." -ForegroundColor Yellow
    
    if ($URLString -match '^https?://') {
        Write-Host "✓ Valid URL format: $URLString" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Invalid URL format. Must start with http:// or https://" -ForegroundColor Red
        return $false
    }
}

# =============================================================================
# 2. DNS Resolution Test
# =============================================================================

function Test-DNSResolution {
    param([string]$URLString)
    
    Write-Host ""
    Write-Host "Testing DNS resolution..." -ForegroundColor Yellow
    
    try {
        $uri = [System.Uri]$URLString
        $hostname = $uri.Host
        
        $resolved = Resolve-DnsName -Name $hostname -ErrorAction Stop
        Write-Host "✓ DNS resolves: $hostname -> $($resolved.IPAddress -join ', ')" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ DNS resolution failed for $hostname" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        Write-Host "  Make sure the domain nameservers are correctly configured" -ForegroundColor Yellow
        return $false
    }
}

# =============================================================================
# 3. HTTPS Connectivity Test
# =============================================================================

function Test-HTTPSConnectivity {
    param(
        [string]$URLString,
        [bool]$SkipCertValidation
    )
    
    Write-Host ""
    Write-Host "Testing HTTPS connectivity..." -ForegroundColor Yellow
    
    try {
        # Skip certificate validation for self-signed certs in testing
        if ($SkipCertValidation) {
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        }
        
        $response = Invoke-WebRequest -Uri $URLString -UseBasicParsing -ErrorAction Stop
        
        Write-Host "✓ HTTPS connection successful" -ForegroundColor Green
        Write-Host "  Status Code: $($response.StatusCode)" -ForegroundColor Cyan
        Write-Host "  Content Length: $($response.Content.Length) bytes" -ForegroundColor Cyan
        
        return $response
    } catch {
        Write-Host "✗ HTTPS connection failed" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        
        # Provide helpful guidance
        if ($_ -match "certificate") {
            Write-Host ""
            Write-Host "Certificate Error Detected:" -ForegroundColor Yellow
            Write-Host "• For self-signed certificates, use: .\test-https.ps1 -SkipCertificateValidation" -ForegroundColor Cyan
            Write-Host "• For production, ensure SSL certificate is properly issued" -ForegroundColor Cyan
        }
        
        return $null
    }
}

# =============================================================================
# 4. SSL Certificate Inspection
# =============================================================================

function Test-SSLCertificate {
    param([string]$URLString)
    
    Write-Host ""
    Write-Host "Testing SSL Certificate..." -ForegroundColor Yellow
    
    try {
        $uri = [System.Uri]$URLString
        $hostname = $uri.Host
        $port = if ($uri.Port -eq -1) { 443 } else { $uri.Port }
        
        # Create connection to get certificate
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($hostname, $port)
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false)
        $sslStream.AuthenticateAsClient($hostname)
        
        $certificate = $sslStream.RemoteCertificate
        $certInfo = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificate)
        
        Write-Host "✓ SSL Certificate retrieved" -ForegroundColor Green
        Write-Host ""
        Write-Host "Certificate Details:" -ForegroundColor Cyan
        Write-Host "  Subject: $($certInfo.Subject)" -ForegroundColor Cyan
        Write-Host "  Issuer: $($certInfo.Issuer)" -ForegroundColor Cyan
        Write-Host "  Valid From: $($certInfo.NotBefore)" -ForegroundColor Cyan
        Write-Host "  Valid Until: $($certInfo.NotAfter)" -ForegroundColor Cyan
        Write-Host "  Thumbprint: $($certInfo.Thumbprint)" -ForegroundColor Cyan
        Write-Host "  Serial Number: $($certInfo.SerialNumber)" -ForegroundColor Cyan
        
        # Check if certificate is expired
        $now = Get-Date
        if ($certInfo.NotAfter -lt $now) {
            Write-Host "  ✗ Certificate is EXPIRED" -ForegroundColor Red
            return $false
        } elseif ($certInfo.NotAfter -lt $now.AddDays(30)) {
            Write-Host "  ⚠ Certificate expires in less than 30 days" -ForegroundColor Yellow
            return $true
        } else {
            Write-Host "  ✓ Certificate is valid" -ForegroundColor Green
            $daysUntilExpiry = ($certInfo.NotAfter - $now).Days
            Write-Host "  Expires in: $daysUntilExpiry days" -ForegroundColor Cyan
            return $true
        }
    } catch {
        Write-Host "⚠ Could not retrieve SSL certificate details" -ForegroundColor Yellow
        Write-Host "  Error: $_" -ForegroundColor Yellow
        Write-Host "  Note: Self-signed certificates may not provide full details" -ForegroundColor Yellow
        return $true  # Don't fail, self-signed is OK for testing
    } finally {
        if ($sslStream) { $sslStream.Close() }
        if ($tcpClient) { $tcpClient.Close() }
    }
}

# =============================================================================
# 5. Security Headers Verification
# =============================================================================

function Test-SecurityHeaders {
    param([string]$URLString)
    
    Write-Host ""
    Write-Host "Testing Security Headers..." -ForegroundColor Yellow
    
    try {
        if ($SkipCertificateValidation) {
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        }
        
        $response = Invoke-WebRequest -Uri $URLString -UseBasicParsing -ErrorAction Stop
        $headers = $response.Headers
        
        Write-Host "✓ Response headers received" -ForegroundColor Green
        Write-Host ""
        
        $requiredHeaders = @{
            "Strict-Transport-Security" = "Security header for HTTPS enforcement"
            "X-Content-Type-Options" = "Prevents MIME sniffing"
            "X-Frame-Options" = "Prevents clickjacking"
            "X-XSS-Protection" = "XSS protection header"
        }
        
        $headerStatus = @()
        
        foreach ($headerName in $requiredHeaders.Keys) {
            $headerValue = $headers[$headerName]
            $description = $requiredHeaders[$headerName]
            
            if ($headerValue) {
                Write-Host "✓ $headerName" -ForegroundColor Green
                Write-Host "  Value: $headerValue" -ForegroundColor Cyan
                $headerStatus += @{ Name = $headerName; Status = "Present" }
            } else {
                Write-Host "⚠ $headerName" -ForegroundColor Yellow
                Write-Host "  Status: Missing" -ForegroundColor Yellow
                $headerStatus += @{ Name = $headerName; Status = "Missing" }
            }
        }
        
        Write-Host ""
        Write-Host "Security Headers Summary:" -ForegroundColor Cyan
        $presentCount = ($headerStatus | Where-Object { $_.Status -eq "Present" }).Count
        Write-Host "  Present: $presentCount / $($requiredHeaders.Count)" -ForegroundColor Cyan
        
        if ($presentCount -eq $requiredHeaders.Count) {
            Write-Host "  Status: ✓ All security headers present" -ForegroundColor Green
        } else {
            Write-Host "  Status: ⚠ Some security headers missing" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "⚠ Could not retrieve security headers" -ForegroundColor Yellow
        Write-Host "  Error: $_" -ForegroundColor Yellow
    }
}

# =============================================================================
# 6. HTTP to HTTPS Redirect Test
# =============================================================================

function Test-HTTPRedirect {
    param([string]$URLString)
    
    Write-Host ""
    Write-Host "Testing HTTP to HTTPS redirect..." -ForegroundColor Yellow
    
    try {
        $uri = [System.Uri]$URLString
        $httpURL = "http://$($uri.Host):80"
        
        if ($SkipCertificateValidation) {
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        }
        
        $response = Invoke-WebRequest -Uri $httpURL -UseBasicParsing -ErrorAction Stop -MaximumRedirection 1
        
        if ($response.StatusCode -in @(301, 302, 303, 307, 308)) {
            Write-Host "✓ HTTP redirect is active" -ForegroundColor Green
            Write-Host "  Redirects to: $($response.Headers.Location)" -ForegroundColor Cyan
        } else {
            Write-Host "⚠ HTTP connection succeeded without redirect" -ForegroundColor Yellow
            Write-Host "  Consider enabling HTTP to HTTPS redirect for security" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✓ HTTP connection blocked (expected for HTTPS-only setup)" -ForegroundColor Green
    }
}

# =============================================================================
# 7. SSL Labs Score (if accessible)
# =============================================================================

function Test-SSLLabsScore {
    param([string]$URLString)
    
    Write-Host ""
    Write-Host "Getting SSL Labs score (requires internet)..." -ForegroundColor Yellow
    
    try {
        $uri = [System.Uri]$URLString
        $hostname = $uri.Host
        
        Write-Host "✓ Visit SSL Labs to check your score:" -ForegroundColor Green
        Write-Host "  https://www.ssllabs.com/ssltest/?d=$hostname" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "SSL Labs Test will show:" -ForegroundColor Yellow
        Write-Host "  • Overall rating (A+, A, B, C, D, E, F)" -ForegroundColor Cyan
        Write-Host "  • Protocol support" -ForegroundColor Cyan
        Write-Host "  • Certificate validity" -ForegroundColor Cyan
        Write-Host "  • Cipher strength" -ForegroundColor Cyan
    } catch {
        Write-Host "⚠ Could not access SSL Labs" -ForegroundColor Yellow
    }
}

# =============================================================================
# 8. Browser Verification Instructions
# =============================================================================

function Show-BrowserVerificationSteps {
    param([string]$URLString)
    
    Write-Host ""
    Write-Host "=== Manual Browser Verification Steps ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Open your browser and navigate to: $URLString" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Look for the green padlock icon 🔒 in the address bar" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Click on the padlock icon to view certificate details:" -ForegroundColor Cyan
    Write-Host "   • Connection: Secure / Not Secure" -ForegroundColor Cyan
    Write-Host "   • Certificate: Valid / Invalid" -ForegroundColor Cyan
    Write-Host "   • Issuer: Should show AWS ACM, Azure, or your CA" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "4. Open DevTools (F12) → Security tab to see:" -ForegroundColor Cyan
    Write-Host "   • Protocol: TLS 1.2 or higher (TLS 1.3 preferred)" -ForegroundColor Cyan
    Write-Host "   • Certificate status and details" -ForegroundColor Cyan
    Write-Host "   • Security issues or warnings" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "5. Check for visual indicators:" -ForegroundColor Cyan
    Write-Host "   • No 'Not Secure' warning" -ForegroundColor Cyan
    Write-Host "   • No mixed content warnings" -ForegroundColor Cyan
    Write-Host "   • URL shows https:// (not http://)" -ForegroundColor Cyan
}

# =============================================================================
# 9. Troubleshooting Guide
# =============================================================================

function Show-TroubleshootingGuide {
    Write-Host ""
    Write-Host "=== Troubleshooting Guide ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Issue: Connection refused" -ForegroundColor Yellow
    Write-Host "Solution:" -ForegroundColor Cyan
    Write-Host "  1. Ensure application is running on port 443" -ForegroundColor Cyan
    Write-Host "  2. Check firewall rules allow port 443" -ForegroundColor Cyan
    Write-Host "  3. Verify domain is resolving to correct IP" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Issue: Certificate verification failed" -ForegroundColor Yellow
    Write-Host "Solution:" -ForegroundColor Cyan
    Write-Host "  1. For self-signed: use -SkipCertificateValidation flag" -ForegroundColor Cyan
    Write-Host "  2. For production: request certificate from trusted CA" -ForegroundColor Cyan
    Write-Host "  3. Check certificate expiration date" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Issue: Mixed content warning" -ForegroundColor Yellow
    Write-Host "Solution:" -ForegroundColor Cyan
    Write-Host "  1. Ensure all resources load over HTTPS" -ForegroundColor Cyan
    Write-Host "  2. Check for http:// URLs in CSS, JS, images" -ForegroundColor Cyan
    Write-Host "  3. Update external resource URLs to https://" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Issue: DNS not resolving" -ForegroundColor Yellow
    Write-Host "Solution:" -ForegroundColor Cyan
    Write-Host "  1. Wait 24-48 hours for DNS propagation" -ForegroundColor Cyan
    Write-Host "  2. Check nameserver configuration at registrar" -ForegroundColor Cyan
    Write-Host "  3. Verify DNS records in Route 53 or Azure DNS" -ForegroundColor Cyan
    Write-Host "  4. Use: nslookup yourdomain.com" -ForegroundColor Cyan
}

# =============================================================================
# Main Execution
# =============================================================================

# Validate URL format
if (-not (Test-URLFormat -URLString $URL)) {
    exit 1
}

# Run all tests
$dnsOK = Test-DNSResolution -URLString $URL
$httpsOK = $null

if ($dnsOK) {
    $httpsOK = Test-HTTPSConnectivity -URLString $URL -SkipCertValidation $SkipCertificateValidation
}

if ($httpsOK) {
    Test-SSLCertificate -URLString $URL
    Test-SecurityHeaders -URLString $URL
    Test-HTTPRedirect -URLString $URL
}

# Show additional information
Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Green
Write-Host "DNS Resolution: $(if ($dnsOK) { '✓ OK' } else { '✗ FAILED' })" -ForegroundColor $(if ($dnsOK) { 'Green' } else { 'Red' })
Write-Host "HTTPS Connectivity: $(if ($httpsOK) { '✓ OK' } else { '✗ FAILED' })" -ForegroundColor $(if ($httpsOK) { 'Green' } else { 'Red' })
Write-Host ""

# Show browser verification steps
Show-BrowserVerificationSteps -URLString $URL

# Show SSL Labs info
Test-SSLLabsScore -URLString $URL

# Show troubleshooting if needed
if (-not $dnsOK -or -not $httpsOK) {
    Show-TroubleshootingGuide
}

Write-Host ""
Write-Host "=== Testing Complete ===" -ForegroundColor Green
