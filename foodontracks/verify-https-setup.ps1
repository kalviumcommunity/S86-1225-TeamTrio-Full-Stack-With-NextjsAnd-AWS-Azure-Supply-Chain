# =============================================================================
# HTTPS Setup Verification Script
# Purpose: Verify HTTPS, SSL certificates, and security headers
# Usage: .\verify-https-setup.ps1 -URL "https://foodontracks.local"
# =============================================================================

param(
    [string]$URL = "https://foodontracks.local",
    [switch]$SkipCertificateValidation = $false
)

Write-Host "======================================================" -ForegroundColor Green
Write-Host "         HTTPS Configuration Verification" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host "Testing URL: $URL"
Write-Host ""

# Validate URL format
function Test-URL {
    param([string]$URLString)
    
    Write-Host "Step 1: Validating URL format..." -ForegroundColor Yellow
    
    if ($URLString -match '^https?://') {
        Write-Host "[OK] Valid URL format: $URLString" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[FAIL] Invalid URL. Must start with http:// or https://" -ForegroundColor Red
        return $false
    }
}

# Test DNS Resolution
function Test-DNS {
    param([string]$URLString)
    
    Write-Host ""
    Write-Host "Step 2: Testing DNS resolution..." -ForegroundColor Yellow
    
    try {
        $uri = [System.Uri]$URLString
        $hostname = $uri.Host
        
        $resolved = Resolve-DnsName -Name $hostname -ErrorAction Stop
        Write-Host "[OK] DNS resolves: $hostname -> $($resolved.IPAddress -join ', ')" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[FAIL] DNS resolution failed for $hostname" -ForegroundColor Red
        Write-Host "       Error: $_" -ForegroundColor Red
        Write-Host "       Make sure domain nameservers are configured correctly" -ForegroundColor Yellow
        return $false
    }
}

# Test HTTPS Connectivity
function Test-HTTPS {
    param(
        [string]$URLString,
        [bool]$SkipCert
    )
    
    Write-Host ""
    Write-Host "Step 3: Testing HTTPS connectivity..." -ForegroundColor Yellow
    
    try {
        if ($SkipCert) {
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        }
        
        $response = Invoke-WebRequest -Uri $URLString -UseBasicParsing -ErrorAction Stop
        
        Write-Host "[OK] HTTPS connection successful" -ForegroundColor Green
        Write-Host "     Status Code: $($response.StatusCode)" -ForegroundColor Cyan
        Write-Host "     Content Length: $($response.Content.Length) bytes" -ForegroundColor Cyan
        
        return $response
    } catch {
        Write-Host "[FAIL] HTTPS connection failed" -ForegroundColor Red
        Write-Host "       Error: $_" -ForegroundColor Red
        
        if ($_ -match "certificate") {
            Write-Host ""
            Write-Host "       Certificate Issue Detected:" -ForegroundColor Yellow
            Write-Host "       For self-signed: .\verify-https-setup.ps1 -SkipCertificateValidation" -ForegroundColor Cyan
        }
        
        return $null
    }
}

# Test Security Headers
function Test-Headers {
    param([string]$URLString)
    
    Write-Host ""
    Write-Host "Step 4: Checking security headers..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri $URLString -UseBasicParsing -ErrorAction Stop
        $headers = $response.Headers
        
        Write-Host "[OK] Response headers retrieved" -ForegroundColor Green
        
        $headerChecks = @(
            "Strict-Transport-Security",
            "X-Content-Type-Options",
            "X-Frame-Options",
            "X-XSS-Protection"
        )
        
        $found = 0
        foreach ($headerName in $headerChecks) {
            if ($headers.ContainsKey($headerName)) {
                Write-Host "     [FOUND] $headerName" -ForegroundColor Green
                $found++
            } else {
                Write-Host "     [MISSING] $headerName" -ForegroundColor Yellow
            }
        }
        
        Write-Host ""
        Write-Host "     Security Headers: $found/$($headerChecks.Count) present" -ForegroundColor Cyan
        
    } catch {
        Write-Host "[WARN] Could not retrieve security headers" -ForegroundColor Yellow
        Write-Host "       Error: $_" -ForegroundColor Yellow
    }
}

# Main execution
$urlOK = Test-URL -URLString $URL
if (-not $urlOK) { exit 1 }

$dnsOK = Test-DNS -URLString $URL
if (-not $dnsOK) { 
    Write-Host ""
    Write-Host "DNS issue detected. Please configure domain nameservers." -ForegroundColor Yellow
    exit 1
}

$httpsOK = Test-HTTPS -URLString $URL -SkipCert $SkipCertificateValidation
if ($httpsOK) {
    Test-Headers -URLString $URL
}

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "              Verification Summary" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host "DNS Resolution:       $(if ($dnsOK) { '[OK]' } else { '[FAIL]' })" -ForegroundColor $(if ($dnsOK) { 'Green' } else { 'Red' })
Write-Host "HTTPS Connectivity:   $(if ($httpsOK) { '[OK]' } else { '[FAIL]' })" -ForegroundColor $(if ($httpsOK) { 'Green' } else { 'Red' })
Write-Host ""

if ($httpsOK) {
    Write-Host "SUCCESS: HTTPS is properly configured!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verification Steps:" -ForegroundColor Cyan
    Write-Host "1. Open browser and visit: $URL" -ForegroundColor Cyan
    Write-Host "2. Look for green padlock icon in address bar" -ForegroundColor Cyan
    Write-Host "3. Press F12 to open DevTools" -ForegroundColor Cyan
    Write-Host "4. Go to Security tab to verify certificate" -ForegroundColor Cyan
} else {
    Write-Host "FAILED: HTTPS configuration has issues" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Verify domain is properly configured in Route 53 or Azure DNS" -ForegroundColor Yellow
    Write-Host "2. Check that SSL certificate is issued and attached to load balancer" -ForegroundColor Yellow
    Write-Host "3. Verify security group allows port 443 (HTTPS)" -ForegroundColor Yellow
    Write-Host "4. Wait 24-48 hours for DNS propagation if domain is new" -ForegroundColor Yellow
}

Write-Host ""
