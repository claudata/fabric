# Example: List Managed Private Endpoints

This example demonstrates how to use the `Get-FabricManagedPrivateEndpoints.ps1` script.

## Prerequisites

- Azure PowerShell module installed (`Az.Accounts`)
- Authenticated with `Connect-AzAccount`
- Workspace Admin or Fabric Admin permissions
- Your Fabric workspace ID

## Basic Usage

```powershell
# Connect to Azure
Connect-AzAccount

# Set your workspace ID
$workspaceId = "12345678-1234-1234-1234-123456789012"

# Run the script
.\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 -WorkspaceId $workspaceId
```

## Example Output

```
Successfully retrieved 3 managed private endpoint(s)

id                                   name                    provisioningState targetPrivateLinkResourceId
--                                   ----                    ----------------- ---------------------------
abc123-def456-ghi789                 sql-endpoint            Succeeded         /subscriptions/xxx/...
xyz789-uvw456-rst123                 storage-endpoint        Succeeded         /subscriptions/xxx/...
mno456-pqr789-stu012                 cosmosdb-endpoint       Pending           /subscriptions/xxx/...
```

## Advanced Examples

### Save to Variable for Further Processing

```powershell
$endpoints = .\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 `
    -WorkspaceId $workspaceId

# Count by status
$endpoints | Group-Object -Property provisioningState | 
    Select-Object Name, Count
```

### Export to CSV

```powershell
$endpoints = .\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 `
    -WorkspaceId $workspaceId

$endpoints | Export-Csv -Path "endpoints-report.csv" -NoTypeInformation
```

### Use List Format

```powershell
.\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 `
    -WorkspaceId $workspaceId `
    -OutputFormat List
```

## Automation Example

```powershell
# Scheduled task to monitor endpoints
$workspaces = @("workspace-id-1", "workspace-id-2", "workspace-id-3")

foreach ($workspace in $workspaces) {
    Write-Host "Checking workspace: $workspace"
    
    try {
        $endpoints = .\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 `
            -WorkspaceId $workspace -ErrorAction Stop
        
        # Check for any failed endpoints
        $failed = $endpoints | Where-Object { $_.provisioningState -eq "Failed" }
        
        if ($failed.Count -gt 0) {
            Write-Warning "Found $($failed.Count) failed endpoint(s) in workspace $workspace"
            # Send alert email here
        }
    }
    catch {
        Write-Error "Failed to check workspace $workspace : $_"
    }
}
```

## See Also

- [Getting Started Guide](../docs/GETTING-STARTED.md)
- [Fabric REST API Documentation](https://learn.microsoft.com/rest/api/fabric/)
