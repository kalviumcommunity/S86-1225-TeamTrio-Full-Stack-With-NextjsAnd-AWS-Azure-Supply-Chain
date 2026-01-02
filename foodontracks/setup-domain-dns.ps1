# =============================================================================
# Domain & DNS Configuration Setup
# Purpose: Validate and configure custom domain with Route 53 or Azure DNS
# Usage: .\setup-domain-dns.ps1 -Domain "foodontracks.local" -Provider "AWS"
# =============================================================================

param(
    [string]$Domain = "foodontracks.local",
    [ValidateSet("AWS", "Azure")]
    [string]$Provider = "AWS",
    [string]$LoadBalancerDNS = "",
    [string]$HostedZoneId = ""
)

Write-Host "=== Domain & DNS Configuration Setup ===" -ForegroundColor Green
Write-Host "Domain: $Domain"
Write-Host "Provider: $Provider"
Write-Host ""

# =============================================================================
# 1. Validate Domain
# =============================================================================

function Test-DomainValidity {
    param([string]$DomainName)
    
    Write-Host "Validating domain format..." -ForegroundColor Yellow
    
    if ($DomainName -match '^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$') {
        Write-Host "✓ Domain format is valid: $DomainName" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Invalid domain format: $DomainName" -ForegroundColor Red
        return $false
    }
}

# =============================================================================
# 2. DNS Nameserver Validation
# =============================================================================

function Get-DomainNameservers {
    param([string]$DomainName)
    
    Write-Host "Retrieving nameservers for $DomainName..." -ForegroundColor Yellow
    
    try {
        $nameservers = nslookup -type=NS $DomainName 2>$null
        if ($nameservers) {
            Write-Host "✓ Nameservers retrieved" -ForegroundColor Green
            return $nameservers
        } else {
            Write-Host "⚠ Could not retrieve nameservers (this is normal for local testing)" -ForegroundColor Yellow
            return $null
        }
    } catch {
        Write-Host "⚠ Nameserver lookup failed: $_" -ForegroundColor Yellow
        return $null
    }
}

# =============================================================================
# 3. AWS Route 53 Configuration
# =============================================================================

function Setup-AWS-Route53 {
    param(
        [string]$DomainName,
        [string]$LoadBalancerDNS,
        [string]$HostedZoneId
    )
    
    Write-Host ""
    Write-Host "=== AWS Route 53 Setup ===" -ForegroundColor Cyan
    
    # Check for AWS CLI
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Host "✗ AWS CLI is not installed. Install it first:" -ForegroundColor Red
        Write-Host "  https://aws.amazon.com/cli/"
        return $false
    }
    
    Write-Host "✓ AWS CLI found" -ForegroundColor Green
    
    # Check AWS credentials
    Write-Host "Checking AWS credentials..." -ForegroundColor Yellow
    try {
        $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
        Write-Host "✓ AWS authenticated as: $($identity.Arn)" -ForegroundColor Green
    } catch {
        Write-Host "✗ AWS authentication failed. Configure your credentials:" -ForegroundColor Red
        Write-Host "  aws configure"
        return $false
    }
    
    # Create hosted zone if needed
    if ([string]::IsNullOrEmpty($HostedZoneId)) {
        Write-Host ""
        Write-Host "Creating Route 53 Hosted Zone for $DomainName..." -ForegroundColor Yellow
        try {
            $hostedZone = aws route53 create-hosted-zone `
                --name $DomainName `
                --caller-reference (New-Guid).Guid `
                --output json | ConvertFrom-Json
            
            $HostedZoneId = $hostedZone.HostedZone.Id.Split('/')[-1]
            Write-Host "✓ Hosted Zone created: $HostedZoneId" -ForegroundColor Green
            Write-Host "  NS Records to add at your registrar:" -ForegroundColor Yellow
            $hostedZone.DelegationSet.NameServers | ForEach-Object { Write-Host "    $_" }
        } catch {
            Write-Host "✗ Failed to create hosted zone: $_" -ForegroundColor Red
            return $false
        }
    }
    
    # Add A record if load balancer is provided
    if (-not [string]::IsNullOrEmpty($LoadBalancerDNS)) {
        Write-Host ""
        Write-Host "Creating A record for $DomainName -> $LoadBalancerDNS" -ForegroundColor Yellow
        
        $recordSet = @{
            Name = $DomainName
            Type = "A"
            TTL = 300
            ResourceRecords = @(@{ Value = $LoadBalancerDNS })
        }
        
        try {
            aws route53 change-resource-record-sets `
                --hosted-zone-id $HostedZoneId `
                --change-batch @"
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "$DomainName",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "$LoadBalancerDNS"}]
      }
    }
  ]
}
"@
            Write-Host "✓ A record created" -ForegroundColor Green
        } catch {
            Write-Host "⚠ Could not create A record (it may already exist): $_" -ForegroundColor Yellow
        }
    }
    
    # Add www CNAME record
    Write-Host ""
    Write-Host "Creating CNAME record for www.$DomainName" -ForegroundColor Yellow
    try {
        aws route53 change-resource-record-sets `
            --hosted-zone-id $HostedZoneId `
            --change-batch @"
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.$DomainName",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "$DomainName"}]
      }
    }
  ]
}
"@
        Write-Host "✓ CNAME record created" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Could not create CNAME record (it may already exist): $_" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "=== Route 53 Configuration Complete ===" -ForegroundColor Green
    Write-Host "Hosted Zone ID: $HostedZoneId" -ForegroundColor Cyan
    Write-Host "View your records in AWS Console: https://console.aws.amazon.com/route53" -ForegroundColor Cyan
    
    return $true
}

# =============================================================================
# 4. Azure DNS Configuration
# =============================================================================

function Setup-Azure-DNS {
    param([string]$DomainName)
    
    Write-Host ""
    Write-Host "=== Azure DNS Setup ===" -ForegroundColor Cyan
    
    # Check for Azure CLI
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Host "✗ Azure CLI is not installed. Install it first:" -ForegroundColor Red
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
        Write-Host "✗ Azure authentication failed. Log in first:" -ForegroundColor Red
        Write-Host "  az login"
        return $false
    }
    
    # Get or create resource group
    Write-Host ""
    Write-Host "Enter your Azure Resource Group name (or press Enter for 'foodontracks-rg'): " -NoNewline
    $resourceGroup = Read-Host
    if ([string]::IsNullOrEmpty($resourceGroup)) { $resourceGroup = "foodontracks-rg" }
    
    Write-Host "Creating DNS zone in resource group: $resourceGroup" -ForegroundColor Yellow
    try {
        az network dns zone create --resource-group $resourceGroup --name $DomainName
        Write-Host "✓ DNS Zone created" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Could not create DNS zone (it may already exist): $_" -ForegroundColor Yellow
    }
    
    # Get nameservers
    Write-Host "Retrieving Azure nameservers..." -ForegroundColor Yellow
    try {
        $zone = az network dns zone show --resource-group $resourceGroup --name $DomainName --output json | ConvertFrom-Json
        Write-Host "✓ Nameservers to add at your registrar:" -ForegroundColor Green
        $zone.nameServers | ForEach-Object { Write-Host "  $_" }
    } catch {
        Write-Host "✗ Could not retrieve nameservers: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "=== Azure DNS Configuration Complete ===" -ForegroundColor Green
    Write-Host "View your zone in Azure Portal: https://portal.azure.com" -ForegroundColor Cyan
    
    return $true
}

# =============================================================================
# 5. Local Hosts File Configuration (for testing)
# =============================================================================

function Setup-LocalHosts {
    param([string]$DomainName)
    
    Write-Host ""
    Write-Host "=== Local Hosts File Setup (for testing) ===" -ForegroundColor Cyan
    
    $hostsFile = "C:\Windows\System32\drivers\etc\hosts"
    $hostEntry = "127.0.0.1       $DomainName"
    $wwwEntry = "127.0.0.1       www.$DomainName"
    
    Write-Host "Adding entries to hosts file..." -ForegroundColor Yellow
    
    try {
        # Check if running as admin
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Host "⚠ Administrator privileges required to modify hosts file" -ForegroundColor Yellow
            Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
            return $false
        }
        
        $hostsContent = Get-Content $hostsFile -Raw
        
        if ($hostsContent -notcontains $hostEntry) {
            Add-Content $hostsFile "`n$hostEntry"
            Write-Host "✓ Added entry: $hostEntry" -ForegroundColor Green
        } else {
            Write-Host "✓ Entry already exists: $hostEntry" -ForegroundColor Green
        }
        
        if ($hostsContent -notcontains $wwwEntry) {
            Add-Content $hostsFile "`n$wwwEntry"
            Write-Host "✓ Added entry: $wwwEntry" -ForegroundColor Green
        } else {
            Write-Host "✓ Entry already exists: $wwwEntry" -ForegroundColor Green
        }
        
        Write-Host "✓ Hosts file updated successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ Failed to update hosts file: $_" -ForegroundColor Red
        Write-Host "You can manually add these entries to $hostsFile" -ForegroundColor Yellow
        Write-Host "  $hostEntry" -ForegroundColor Yellow
        Write-Host "  $wwwEntry" -ForegroundColor Yellow
        return $false
    }
}

# =============================================================================
# Main Execution
# =============================================================================

# Validate domain
if (-not (Test-DomainValidity -DomainName $Domain)) {
    exit 1
}

# Get nameservers (informational)
Get-DomainNameservers -DomainName $Domain

# Setup based on provider
if ($Provider -eq "AWS") {
    if (-not (Setup-AWS-Route53 -DomainName $Domain -LoadBalancerDNS $LoadBalancerDNS -HostedZoneId $HostedZoneId)) {
        exit 1
    }
} else {
    if (-not (Setup-Azure-DNS -DomainName $Domain)) {
        exit 1
    }
}

# Setup local hosts for testing
if ((Read-Host "Do you want to add entries to your local hosts file for testing? (y/n)") -eq 'y') {
    Setup-LocalHosts -DomainName $Domain
}

Write-Host ""
Write-Host "=== Domain Setup Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. If using external registrar, add the nameservers from above" -ForegroundColor Cyan
Write-Host "2. Wait 24-48 hours for DNS propagation" -ForegroundColor Cyan
Write-Host "3. Run './setup-ssl-certificate.ps1' to configure SSL" -ForegroundColor Cyan
Write-Host "4. Run './test-https.ps1' to verify HTTPS setup" -ForegroundColor Cyan
