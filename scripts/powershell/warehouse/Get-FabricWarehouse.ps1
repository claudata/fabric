<#
.SYNOPSIS
    Lists all warehouses in a Microsoft Fabric workspace.

.DESCRIPTION
    This script retrieves and displays all Fabric Data Warehouses in a specified 
    workspace using the Fabric REST API.

.PARAMETER WorkspaceId
    The ID (GUID) of the Fabric workspace to query. This is a required parameter.

.PARAMETER IncludeConnectionString
    If specified, includes the SQL connection endpoint for each warehouse.

.EXAMPLE
    .\Get-FabricWarehouse.ps1 -WorkspaceId "12345678-1234-1234-1234-123456789012"
    
    Lists all warehouses in the specified workspace.

.EXAMPLE
    .\Get-FabricWarehouse.ps1 -WorkspaceId "12345678-1234-1234-1234-123456789012" -IncludeConnectionString
    
    Lists warehouses with their SQL connection endpoints.

.NOTES
    Author: Claudio Da Silva
    Requires: Az.Accounts module (for Get-AzAccessToken)
    Requires: Valid Azure authentication with Fabric permissions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Enter the Fabric workspace ID (GUID)")]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceId,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeConnectionString
)

$ErrorActionPreference = 'Stop'

try {
    # Verify Az.Accounts module is available
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        throw "Az.Accounts module is not installed. Please install it using: Install-Module -Name Az.Accounts"
    }

    Write-Verbose "Retrieving access token for Fabric API..."
    $token = (Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com").Token

    if ([string]::IsNullOrEmpty($token)) {
        throw "Failed to retrieve access token. Please ensure you are authenticated with Connect-AzAccount."
    }

    # Define the API URL to get all items in workspace
    $apiUrl = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items"
    Write-Verbose "API URL: $apiUrl"

    # Define the request headers
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }

    # Make the API request
    Write-Verbose "Sending GET request to Fabric API..."
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers

    # Filter for warehouses only
    $warehouses = $response.value | Where-Object { $_.type -eq "Warehouse" }

    if ($null -ne $warehouses) {
        $warehouseCount = @($warehouses).Count
        Write-Host "Successfully retrieved $warehouseCount warehouse(s)" -ForegroundColor Green
        Write-Host ""

        if ($warehouseCount -gt 0) {
            foreach ($warehouse in $warehouses) {
                $output = [PSCustomObject]@{
                    Id          = $warehouse.id
                    Name        = $warehouse.displayName
                    Description = $warehouse.description
                }

                if ($IncludeConnectionString) {
                    # Get warehouse properties for connection string
                    $warehouseApiUrl = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/warehouses/$($warehouse.id)"
                    $warehouseDetails = Invoke-RestMethod -Uri $warehouseApiUrl -Method Get -Headers $headers
                    
                    $output | Add-Member -NotePropertyName "ConnectionString" -NotePropertyValue $warehouseDetails.properties.connectionString
                }

                $output
            }
        } else {
            Write-Host "No warehouses found in workspace: $WorkspaceId" -ForegroundColor Yellow
        }

        return $warehouses
    } else {
        Write-Warning "No items returned from the API. The workspace may not exist or you may not have access."
    }
}
catch {
    Write-Error "An error occurred while retrieving warehouses: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        Write-Error "Status Code: $($_.Exception.Response.StatusCode.value__)"
    }
    exit 1
}
