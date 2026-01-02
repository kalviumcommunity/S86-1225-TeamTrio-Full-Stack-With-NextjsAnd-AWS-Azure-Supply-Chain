# =============================================================================
# SSL Certificate Setup & Management
# Purpose: Request and apply SSL certificates via AWS ACM or Azure App Service
# Usage: .\setup-ssl-certificate.ps1 -Domain "foodontracks.local" -Provider "AWS"
# =============================================================================

param(
    [string]$Domain = "foodontracks.local",
    [ValidateSet("AWS", "Azure")]
    [string]$Provider = "AWS",
    [string]$CertificateArn = "",
    [string]$AppServiceName = "",
    [string]$ResourceGroup = ""
)

Write-Host "=== SSL Certificate Setup ===" -ForegroundColor Green
Write-Host "Domain: $Domain"
Write-Host "Provider: $Provider"
Write-Host ""

# =============================================================================
# 1. Validate Domain Ownership
# =============================================================================

function Test-DomainDNS {
    param([string]$DomainName)
    
    Write-Host "Validating domain DNS resolution..." -ForegroundColor Yellow
    
    try {
        $resolved = Resolve-DnsName -Name $DomainName -ErrorAction Stop
        Write-Host "✓ Domain resolves to: $($resolved.IPAddress -join ', ')" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "⚠ Domain does not resolve yet. This is expected for new domains." -ForegroundColor Yellow
        Write-Host "   DNS may take 24-48 hours to propagate" -ForegroundColor Yellow
        return $true  # Don't fail, DNS might not be ready
    }
}

# =============================================================================
# 2. AWS Certificate Manager (ACM) Setup
# =============================================================================

function Setup-AWS-ACM {
    param(
        [string]$DomainName,
        [string]$CertificateArn
    )
    
    Write-Host ""
    Write-Host "=== AWS Certificate Manager (ACM) Setup ===" -ForegroundColor Cyan
    
    # Check for AWS CLI
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Host "✗ AWS CLI is not installed. Install it from:" -ForegroundColor Red
        Write-Host "  https://aws.amazon.com/cli/"
        return $false
    }
    
    Write-Host "✓ AWS CLI found" -ForegroundColor Green
    
    # Check AWS authentication
    Write-Host "Checking AWS credentials..." -ForegroundColor Yellow
    try {
        $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
        Write-Host "✓ AWS authenticated as: $($identity.Arn)" -ForegroundColor Green
    } catch {
        Write-Host "✗ AWS authentication failed" -ForegroundColor Red
        Write-Host "  Run: aws configure" -ForegroundColor Yellow
        return $false
    }
    
    # Request certificate if not provided
    if ([string]::IsNullOrEmpty($CertificateArn)) {
        Write-Host ""
        Write-Host "Requesting new certificate for $DomainName..." -ForegroundColor Yellow
        Write-Host "This certificate will also cover www.$DomainName" -ForegroundColor Yellow
        
        try {
            $certificate = aws acm request-certificate `
                --domain-name $DomainName `
                --subject-alternative-names "www.$DomainName" `
                --validation-method DNS `
                --region us-east-1 `
                --output json | ConvertFrom-Json
            
            $CertificateArn = $certificate.CertificateArn
            Write-Host "✓ Certificate requested: $CertificateArn" -ForegroundColor Green
            Write-Host ""
            Write-Host "Certificate Status: PENDING_VALIDATION" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host "1. Go to AWS ACM Console: https://console.aws.amazon.com/acm" -ForegroundColor Cyan
            Write-Host "2. Select the certificate for $DomainName" -ForegroundColor Cyan
            Write-Host "3. Copy the CNAME validation records" -ForegroundColor Cyan
            Write-Host "4. Add them to your Route 53 hosted zone" -ForegroundColor Cyan
            Write-Host "5. Wait for status to change to ISSUED (usually 5-30 minutes)" -ForegroundColor Cyan
        } catch {
            Write-Host "✗ Failed to request certificate: $_" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "Using provided certificate ARN: $CertificateArn" -ForegroundColor Cyan
    }
    
    # Validate certificate status
    Write-Host ""
    Write-Host "Checking certificate status..." -ForegroundColor Yellow
    try {
        $certDetails = aws acm describe-certificate `
            --certificate-arn $CertificateArn `
            --region us-east-1 `
            --output json | ConvertFrom-Json
        
        $status = $certDetails.Certificate.Status
        Write-Host "Certificate Status: $status" -ForegroundColor $(if ($status -eq "ISSUED") { "Green" } else { "Yellow" })
        
        if ($status -eq "PENDING_VALIDATION") {
            Write-Host ""
            Write-Host "⚠ Certificate is still pending validation." -ForegroundColor Yellow
            Write-Host "Please complete the DNS validation steps and try again later." -ForegroundColor Yellow
            
            # Show validation records if available
            if ($certDetails.Certificate.DomainValidationOptions) {
                Write-Host ""
                Write-Host "DNS Validation Records to add:" -ForegroundColor Cyan
                $certDetails.Certificate.DomainValidationOptions | ForEach-Object {
                    Write-Host "  Domain: $($_.DomainName)" -ForegroundColor Cyan
                    if ($_.ResourceRecord) {
                        Write-Host "    Name: $($_.ResourceRecord.Name)" -ForegroundColor Cyan
                        Write-Host "    Type: $($_.ResourceRecord.Type)" -ForegroundColor Cyan
                        Write-Host "    Value: $($_.ResourceRecord.Value)" -ForegroundColor Cyan
                    }
                }
            }
        } elseif ($status -eq "ISSUED") {
            Write-Host "✓ Certificate is valid and ready to use" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠ Could not verify certificate status: $_" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "=== AWS Certificate Manager Setup Complete ===" -ForegroundColor Green
    Write-Host "Certificate ARN: $CertificateArn" -ForegroundColor Cyan
    Write-Host "Next: Attach this certificate to your Load Balancer or CloudFront distribution" -ForegroundColor Yellow
    
    return $true
}

# =============================================================================
# 3. Azure App Service Certificate Setup
# =============================================================================

function Setup-Azure-Certificate {
    param(
        [string]$DomainName,
        [string]$AppServiceName,
        [string]$ResourceGroup
    )
    
    Write-Host ""
    Write-Host "=== Azure App Service Certificate Setup ===" -ForegroundColor Cyan
    
    # Check for Azure CLI
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Host "✗ Azure CLI is not installed. Install it from:" -ForegroundColor Red
        Write-Host "  https://docs.microsoft.com/en-us/cli/azure/"
        return $false
    }
    
    Write-Host "✓ Azure CLI found" -ForegroundColor Green
    
    # Check Azure authentication
    Write-Host "Checking Azure authentication..." -ForegroundColor Yellow
    try {
        $account = az account show --output json | ConvertFrom-Json
        Write-Host "✓ Azure authenticated as: $($account.userPrincipalName)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Azure authentication failed" -ForegroundColor Red
        Write-Host "  Run: az login" -ForegroundColor Yellow
        return $false
    }
    
    if ([string]::IsNullOrEmpty($AppServiceName)) {
        Write-Host ""
        Write-Host "Enter your App Service name: " -NoNewline
        $AppServiceName = Read-Host
    }
    
    if ([string]::IsNullOrEmpty($ResourceGroup)) {
        Write-Host "Enter your Resource Group name: " -NoNewline
        $ResourceGroup = Read-Host
    }
    
    # Create managed certificate
    Write-Host ""
    Write-Host "Creating managed certificate for $DomainName..." -ForegroundColor Yellow
    
    try {
        az webapp config ssl create `
            --resource-group $ResourceGroup `
            --name $AppServiceName `
            --certificate-name "$($DomainName.Replace('.', '-'))-cert"
        
        Write-Host "✓ Managed certificate created" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Could not create certificate (it may already exist): $_" -ForegroundColor Yellow
    }
    
    # Add custom domain
    Write-Host ""
    Write-Host "Adding custom domain to App Service..." -ForegroundColor Yellow
    
    try {
        az webapp config hostname add `
            --resource-group $ResourceGroup `
            --webapp-name $AppServiceName `
            --hostname $DomainName
        
        Write-Host "✓ Custom domain added" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Could not add domain (it may already be added): $_" -ForegroundColor Yellow
    }
    
    # Enable HTTPS only
    Write-Host ""
    Write-Host "Enabling HTTPS only..." -ForegroundColor Yellow
    
    try {
        az webapp update `
            --resource-group $ResourceGroup `
            --name $AppServiceName `
            --set httpsOnly=true
        
        Write-Host "✓ HTTPS Only enabled" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to enable HTTPS Only: $_" -ForegroundColor Red
        return $false
    }
    
    # Bind certificate
    Write-Host ""
    Write-Host "Binding certificate to domain..." -ForegroundColor Yellow
    
    try {
        # Get the certificate thumbprint
        $cert = az webapp config ssl list `
            --resource-group $ResourceGroup `
            --name $AppServiceName `
            --output json | ConvertFrom-Json
        
        if ($cert) {
            $thumbprint = $cert[0].Thumbprint
            az webapp config ssl bind `
                --resource-group $ResourceGroup `
                --name $AppServiceName `
                --certificate-thumbprint $thumbprint `
                --ssl-type SNI
            
            Write-Host "✓ Certificate bound to domain" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠ Could not bind certificate: $_" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "=== Azure Certificate Setup Complete ===" -ForegroundColor Green
    Write-Host "App Service: $AppServiceName" -ForegroundColor Cyan
    Write-Host "Custom Domain: $DomainName" -ForegroundColor Cyan
    Write-Host "HTTPS Status: Enabled" -ForegroundColor Green
    
    return $true
}

# =============================================================================
# 4. Generate Self-Signed Certificate (for local testing only)
# =============================================================================

function New-SelfSignedCertificate {
    param(
        [string]$DomainName,
        [string]$OutputPath = "./certs"
    )
    
    Write-Host ""
    Write-Host "=== Generating Self-Signed Certificate (Local Testing Only) ===" -ForegroundColor Cyan
    Write-Host "⚠ Self-signed certificates are NOT for production!" -ForegroundColor Yellow
    
    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "✓ Created directory: $OutputPath" -ForegroundColor Green
    }
    
    $certPath = Join-Path $OutputPath "$($DomainName).crt"
    $keyPath = Join-Path $OutputPath "$($DomainName).key"
    $pfxPath = Join-Path $OutputPath "$($DomainName).pfx"
    
    Write-Host "Generating certificate for $DomainName..." -ForegroundColor Yellow
    
    try {
        # Create self-signed certificate (Windows built-in)
        $cert = New-SelfSignedCertificate `
            -CertStoreLocation cert:\CurrentUser\My `
            -DnsName $DomainName, "www.$DomainName" `
            -FriendlyName "FoodONtracks - $DomainName" `
            -KeyLength 2048 `
            -KeyExportPolicy Exportable `
            -KeyUsage DigitalSignature, KeyEncipherment `
            -NotAfter (Get-Date).AddYears(1)
        
        Write-Host "✓ Certificate generated" -ForegroundColor Green
        Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Cyan
        
        # Export to PFX for use with services
        $password = ConvertTo-SecureString "FoodONtracks2024!" -AsPlainText -Force
        Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $password | Out-Null
        
        Write-Host "✓ Exported to PFX: $pfxPath" -ForegroundColor Green
        Write-Host "  Password: FoodONtracks2024!" -ForegroundColor Yellow
        
        Write-Host ""
        Write-Host "Certificate Details:" -ForegroundColor Cyan
        Write-Host "  Subject: $($cert.Subject)" -ForegroundColor Cyan
        Write-Host "  Valid From: $($cert.NotBefore)" -ForegroundColor Cyan
        Write-Host "  Valid Until: $($cert.NotAfter)" -ForegroundColor Cyan
        
        return $true
    } catch {
        Write-Host "✗ Failed to generate certificate: $_" -ForegroundColor Red
        return $false
    }
}

# =============================================================================
# 5. Display Certificate Information
# =============================================================================

function Show-CertificateInfo {
    param(
        [string]$Domain,
        [string]$CertificateArn = "",
        [string]$AppServiceName = "",
        [string]$ResourceGroup = ""
    )
    
    Write-Host ""
    Write-Host "=== Certificate Information ===" -ForegroundColor Cyan
    Write-Host "Domain: $Domain" -ForegroundColor Cyan
    
    if (-not [string]::IsNullOrEmpty($CertificateArn)) {
        Write-Host "AWS Certificate ARN: $CertificateArn" -ForegroundColor Cyan
    }
    
    if (-not [string]::IsNullOrEmpty($AppServiceName)) {
        Write-Host "Azure App Service: $AppServiceName" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "SSL/TLS Best Practices:" -ForegroundColor Yellow
    Write-Host "• Always use HTTPS in production" -ForegroundColor Cyan
    Write-Host "• Enable HSTS (HTTP Strict-Transport-Security)" -ForegroundColor Cyan
    Write-Host "• Use DNS validation for certificate renewal" -ForegroundColor Cyan
    Write-Host "• Monitor certificate expiration (set alerts 30 days before)" -ForegroundColor Cyan
    Write-Host "• Test with SSL Labs: https://www.ssllabs.com/ssltest/" -ForegroundColor Cyan
}

# =============================================================================
# Main Execution
# =============================================================================

# Validate domain DNS first
Test-DomainDNS -DomainName $Domain

# Setup based on provider
if ($Provider -eq "AWS") {
    if (-not (Setup-AWS-ACM -DomainName $Domain -CertificateArn $CertificateArn)) {
        Write-Host ""
        Write-Host "Would you like to generate a self-signed certificate for local testing? (y/n): " -NoNewline
        if ((Read-Host) -eq 'y') {
            New-SelfSignedCertificate -DomainName $Domain
        }
        exit 1
    }
} else {
    if (-not (Setup-Azure-Certificate -DomainName $Domain -AppServiceName $AppServiceName -ResourceGroup $ResourceGroup)) {
        Write-Host ""
        Write-Host "Would you like to generate a self-signed certificate for local testing? (y/n): " -NoNewline
        if ((Read-Host) -eq 'y') {
            New-SelfSignedCertificate -DomainName $Domain
        }
        exit 1
    }
}

# Display info and next steps
Show-CertificateInfo -Domain $Domain -CertificateArn $CertificateArn -AppServiceName $AppServiceName -ResourceGroup $ResourceGroup

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Ensure your domain nameservers are pointing to your provider's DNS" -ForegroundColor Cyan
Write-Host "2. For AWS: Attach the certificate to your Load Balancer/CloudFront" -ForegroundColor Cyan
Write-Host "3. For Azure: Certificate should auto-bind to your App Service" -ForegroundColor Cyan
Write-Host "4. Run './test-https.ps1' to verify HTTPS is working" -ForegroundColor Cyan
