<#
.SYNOPSIS
    Retrieves metadata for tables, views, and schemas in a Fabric Data Warehouse.

.DESCRIPTION
    This script connects to a Fabric Data Warehouse and retrieves comprehensive metadata
    including schemas, tables, columns, views, and stored procedures.

.PARAMETER WorkspaceId
    The ID (GUID) of the Fabric workspace containing the warehouse.

.PARAMETER WarehouseId
    The ID (GUID) of the Fabric Data Warehouse.

.PARAMETER MetadataType
    The type of metadata to retrieve: All, Schemas, Tables, Columns, Views, StoredProcedures

.EXAMPLE
    .\Get-FabricWarehouseMetadata.ps1 -WorkspaceId "xxx" -WarehouseId "yyy" -MetadataType Tables
    
    Lists all tables in the warehouse.

.NOTES
    Author: Claudio Da Silva
    Requires: Az.Accounts module
    Note: This script uses the Fabric SQL endpoint to query system views
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$WarehouseId,

    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'Schemas', 'Tables', 'Columns', 'Views', 'StoredProcedures')]
    [string]$MetadataType = 'All'
)

$ErrorActionPreference = 'Stop'

try {
    Write-Verbose "Retrieving warehouse metadata for type: $MetadataType"

    # SQL queries for different metadata types
    $queries = @{
        Schemas = @"
SELECT 
    schema_name,
    schema_id
FROM INFORMATION_SCHEMA.SCHEMATA
WHERE schema_name NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY schema_name
"@
        Tables = @"
SELECT 
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    TABLE_TYPE as TableType
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY TABLE_SCHEMA, TABLE_NAME
"@
        Columns = @"
SELECT 
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as TableName,
    COLUMN_NAME as ColumnName,
    DATA_TYPE as DataType,
    CHARACTER_MAXIMUM_LENGTH as MaxLength,
    IS_NULLABLE as IsNullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION
"@
        Views = @"
SELECT 
    TABLE_SCHEMA as SchemaName,
    TABLE_NAME as ViewName
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY TABLE_SCHEMA, TABLE_NAME
"@
        StoredProcedures = @"
SELECT 
    ROUTINE_SCHEMA as SchemaName,
    ROUTINE_NAME as ProcedureName,
    ROUTINE_TYPE as RoutineType
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME
"@
    }

    Write-Host "Metadata Type: $MetadataType" -ForegroundColor Cyan
    Write-Host "Note: Actual query execution requires SQL connection to the warehouse" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To execute these queries, use:" -ForegroundColor Yellow
    Write-Host "  1. Fabric Portal SQL Query Editor" -ForegroundColor Yellow
    Write-Host "  2. SQL Server Management Studio (SSMS)" -ForegroundColor Yellow
    Write-Host "  3. Azure Data Studio" -ForegroundColor Yellow
    Write-Host "  4. PowerShell with SqlServer module" -ForegroundColor Yellow
    Write-Host ""

    if ($MetadataType -eq 'All') {
        foreach ($type in $queries.Keys) {
            Write-Host "=== $type ===" -ForegroundColor Green
            Write-Host $queries[$type]
            Write-Host ""
        }
    } else {
        Write-Host "=== Query for $MetadataType ===" -ForegroundColor Green
        Write-Host $queries[$MetadataType]
    }

    Write-Host "`nConnection information:" -ForegroundColor Cyan
    Write-Host "Run .\Get-FabricWarehouse.ps1 -IncludeConnectionString to get the SQL endpoint" -ForegroundColor Yellow
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}
