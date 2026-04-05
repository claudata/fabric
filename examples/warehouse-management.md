# Example: Managing Fabric Data Warehouses

This example demonstrates how to list and manage Fabric Data Warehouses using PowerShell.

## Prerequisites

- Azure PowerShell module installed (`Az.Accounts`)
- Authenticated with `Connect-AzAccount`
- Workspace Admin or Fabric Admin permissions
- Your Fabric workspace ID

## List All Warehouses

```powershell
# Connect to Azure
Connect-AzAccount

# Set your workspace ID
$workspaceId = "12345678-1234-1234-1234-123456789012"

# List all warehouses
.\scripts\powershell\warehouse\Get-FabricWarehouse.ps1 -WorkspaceId $workspaceId
```

## Get Warehouse with Connection String

```powershell
# Include SQL connection endpoint
.\scripts\powershell\warehouse\Get-FabricWarehouse.ps1 `
    -WorkspaceId $workspaceId `
    -IncludeConnectionString
```

Example output:
```
Successfully retrieved 2 warehouse(s)

Id          : abc123-def456-ghi789
Name        : SalesWarehouse
Description : Production sales data warehouse
ConnectionString : your-warehouse.datawarehouse.fabric.microsoft.com
```

## Get Warehouse Metadata

```powershell
# Get table metadata
.\scripts\powershell\warehouse\Get-FabricWarehouseMetadata.ps1 `
    -WorkspaceId $workspaceId `
    -WarehouseId "abc123-def456-ghi789" `
    -MetadataType Tables
```

This will generate SQL queries you can run in the warehouse to retrieve metadata:

```sql
SELECT 
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    TABLE_TYPE as TableType
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY TABLE_SCHEMA, TABLE_NAME
```

## Automation Example

```powershell
# Get all warehouses and export to CSV
$warehouses = .\scripts\powershell\warehouse\Get-FabricWarehouse.ps1 `
    -WorkspaceId $workspaceId `
    -IncludeConnectionString

$warehouses | Export-Csv -Path "warehouses-inventory.csv" -NoTypeInformation
Write-Host "Exported $($warehouses.Count) warehouse(s) to warehouses-inventory.csv"
```

## Multi-Workspace Inventory

```powershell
# Check multiple workspaces
$workspaces = @{
    "Production" = "prod-workspace-id"
    "Development" = "dev-workspace-id"
    "Testing" = "test-workspace-id"
}

$allWarehouses = @()

foreach ($workspace in $workspaces.GetEnumerator()) {
    Write-Host "`n=== $($workspace.Key) Workspace ===" -ForegroundColor Cyan
    
    $warehouses = .\scripts\powershell\warehouse\Get-FabricWarehouse.ps1 `
        -WorkspaceId $workspace.Value
    
    foreach ($wh in $warehouses) {
        $wh | Add-Member -NotePropertyName "Environment" -NotePropertyValue $workspace.Key
        $allWarehouses += $wh
    }
}

# Export complete inventory
$allWarehouses | Export-Csv -Path "all-warehouses.csv" -NoTypeInformation
```

## See Also

- [Data Pipeline Examples](pipeline-examples.md)
- [Warehouse Data Loading](warehouse-loading.md)
- [Getting Started Guide](../docs/GETTING-STARTED.md)
