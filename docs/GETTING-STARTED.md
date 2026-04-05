# Getting Started with Fabric Automation

This guide will help you get started with automating Microsoft Fabric using the scripts in this repository.

## Table of Contents
1. [Initial Setup](#initial-setup)
2. [Authentication Methods](#authentication-methods)
3. [Common Scenarios](#common-scenarios)
4. [Troubleshooting](#troubleshooting)

## Initial Setup

### Step 1: Install Prerequisites

```powershell
# Install Azure PowerShell module
Install-Module -Name Az.Accounts -Scope CurrentUser -Repository PSGallery -Force

# Verify installation
Get-Module -ListAvailable Az.Accounts
```

### Step 2: Authenticate

```powershell
# Interactive login
Connect-AzAccount

# Verify you can access Fabric API
$token = Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com"
Write-Host "Token acquired successfully!" -ForegroundColor Green
```

### Step 3: Find Your Workspace ID

1. Navigate to your Fabric workspace in the browser
2. Copy the workspace ID from the URL:
   ```
   https://app.fabric.microsoft.com/groups/12345678-1234-1234-1234-123456789012/...
                                          ^^^^^^^^ This is your Workspace ID ^^^^^^^^
   ```

## Authentication Methods

### Interactive Login (Development)
Best for: Local development and testing

```powershell
Connect-AzAccount
```

### Service Principal (Automation)
Best for: CI/CD pipelines and automated scripts

```powershell
# Set up variables (use Azure Key Vault in production!)
$appId = $env:AZURE_CLIENT_ID
$secret = $env:AZURE_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
$tenantId = $env:AZURE_TENANT_ID

# Create credential
$credential = New-Object System.Management.Automation.PSCredential($appId, $secret)

# Connect
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId
```

### Managed Identity (Azure Resources)
Best for: Azure VMs, Azure Automation, Azure Functions

```powershell
Connect-AzAccount -Identity
```

## Common Scenarios

### Scenario 1: List All Private Endpoints

```powershell
# Set your workspace ID
$workspaceId = "your-workspace-id-here"

# Run the script
$endpoints = .\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 `
    -WorkspaceId $workspaceId `
    -Verbose

# Display results
$endpoints | Format-Table
```

### Scenario 2: Filter Endpoints by Status

```powershell
# Get all endpoints
$endpoints = .\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 `
    -WorkspaceId $workspaceId

# Filter by provisioning state
$succeeded = $endpoints | Where-Object { $_.provisioningState -eq "Succeeded" }
$pending = $endpoints | Where-Object { $_.provisioningState -eq "Pending" }

Write-Host "Succeeded: $($succeeded.Count)" -ForegroundColor Green
Write-Host "Pending: $($pending.Count)" -ForegroundColor Yellow
```

### Scenario 3: Export to CSV

```powershell
# Get endpoints and export
$endpoints = .\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 `
    -WorkspaceId $workspaceId

$endpoints | Export-Csv -Path "fabric-endpoints.csv" -NoTypeInformation
Write-Host "Exported to fabric-endpoints.csv"
```

### Scenario 4: Monitor Multiple Workspaces

```powershell
# Define multiple workspaces
$workspaces = @{
    "Production" = "prod-workspace-id"
    "Development" = "dev-workspace-id"
    "Testing" = "test-workspace-id"
}

# Check each workspace
foreach ($workspace in $workspaces.GetEnumerator()) {
    Write-Host "`n=== $($workspace.Key) Workspace ===" -ForegroundColor Cyan
    
    $endpoints = .\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 `
        -WorkspaceId $workspace.Value
    
    Write-Host "Total endpoints: $($endpoints.Count)"
}
```

## Troubleshooting

### Issue: "Failed to retrieve access token"

**Solution:**
```powershell
# Clear Azure context and re-authenticate
Disconnect-AzAccount
Clear-AzContext -Force
Connect-AzAccount
```

### Issue: "403 Forbidden" Error

**Cause:** Insufficient permissions

**Solution:**
- Ensure you have Fabric Admin or Workspace Admin role
- Verify the workspace ID is correct
- Check that your Azure AD user/service principal has proper RBAC assignments

### Issue: "Module Az.Accounts not found"

**Solution:**
```powershell
# Install the module
Install-Module -Name Az.Accounts -Scope CurrentUser -Force

# Import it
Import-Module Az.Accounts
```

### Issue: Script Execution Policy Error

**Solution:**
```powershell
# Check current policy
Get-ExecutionPolicy

# Set to RemoteSigned (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Best Practices

1. **Never hardcode credentials** - Use Azure Key Vault or environment variables
2. **Use service principals for automation** - Create dedicated service principals with minimum required permissions
3. **Enable verbose logging during development** - Use the `-Verbose` parameter
4. **Test in non-production first** - Always validate scripts in dev/test workspaces
5. **Handle errors gracefully** - Wrap scripts in try/catch blocks
6. **Keep tokens secure** - Never log or display access tokens

## Next Steps

- Explore the [examples](../examples/) directory for more scenarios
- Check the [PowerShell script documentation](../scripts/powershell/)
- Review [Contributing Guidelines](../CONTRIBUTING.md) to add your own scripts

## Need Help?

- Open an [issue](https://github.com/claudata/fabric/issues) on GitHub
- Check the [Fabric REST API documentation](https://learn.microsoft.com/rest/api/fabric/)
- Review [Microsoft Fabric documentation](https://learn.microsoft.com/fabric/)
