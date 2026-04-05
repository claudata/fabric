<#
.SYNOPSIS
    Lists managed private endpoints in a Microsoft Fabric workspace.

.DESCRIPTION
    This script retrieves and displays all managed private endpoints configured in a 
    specified Microsoft Fabric workspace using the Fabric REST API.

.PARAMETER WorkspaceId
    The ID (GUID) of the Fabric workspace to query. This is a required parameter.

.PARAMETER OutputFormat
    The format for output display. Valid values are 'Table' (default) or 'List'.

.EXAMPLE
    .\Get-FabricManagedPrivateEndpoints.ps1 -WorkspaceId "12345678-1234-1234-1234-123456789012"
    
    Lists all managed private endpoints in the specified workspace in table format.

.EXAMPLE
    .\Get-FabricManagedPrivateEndpoints.ps1 -WorkspaceId "12345678-1234-1234-1234-123456789012" -OutputFormat List
    
    Lists all managed private endpoints in list format.

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
    [ValidateSet('Table', 'List')]
    [string]$OutputFormat = 'Table'
)

# Error handling preference
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

    # Define the API URL
    $apiUrl = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/managedPrivateEndpoints/"
    Write-Verbose "API URL: $apiUrl"

    # Define the request headers
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }

    # Make the API request
    Write-Verbose "Sending GET request to Fabric API..."
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers

    # Process and display the response
    if ($null -ne $response -and $null -ne $response.value) {
        $endpointCount = $response.value.Count
        Write-Host "Successfully retrieved $endpointCount managed private endpoint(s)" -ForegroundColor Green
        Write-Host ""

        if ($endpointCount -gt 0) {
            if ($OutputFormat -eq 'Table') {
                $response.value | Format-Table -Property id, name, provisioningState, targetPrivateLinkResourceId -AutoSize
            } else {
                $response.value | Format-List -Property id, name, provisioningState, targetPrivateLinkResourceId
            }
        } else {
            Write-Host "No managed private endpoints found in workspace: $WorkspaceId" -ForegroundColor Yellow
        }

        # Return the data for pipeline usage
        return $response.value
    } else {
        Write-Warning "No data returned from the API. The workspace may not exist or you may not have access."
    }
}
catch {
    Write-Error "An error occurred while retrieving managed private endpoints: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        Write-Error "Status Code: $($_.Exception.Response.StatusCode.value__)"
    }
    exit 1
}
