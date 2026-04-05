<#
.SYNOPSIS
    Lists all data pipelines in a Microsoft Fabric workspace.

.DESCRIPTION
    This script retrieves and displays all Data Factory pipelines in a specified 
    Fabric workspace using the Fabric REST API.

.PARAMETER WorkspaceId
    The ID (GUID) of the Fabric workspace to query. This is a required parameter.

.PARAMETER IncludeDefinition
    If specified, includes the pipeline definition (JSON) for each pipeline.

.EXAMPLE
    .\Get-FabricDataPipeline.ps1 -WorkspaceId "12345678-1234-1234-1234-123456789012"
    
    Lists all pipelines in the specified workspace.

.EXAMPLE
    .\Get-FabricDataPipeline.ps1 -WorkspaceId "12345678-1234-1234-1234-123456789012" -IncludeDefinition
    
    Lists pipelines with their complete definitions.

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
    [switch]$IncludeDefinition
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

    # Filter for Data Pipelines only
    $pipelines = $response.value | Where-Object { $_.type -eq "DataPipeline" }

    if ($null -ne $pipelines) {
        $pipelineCount = @($pipelines).Count
        Write-Host "Successfully retrieved $pipelineCount pipeline(s)" -ForegroundColor Green
        Write-Host ""

        if ($pipelineCount -gt 0) {
            $results = foreach ($pipeline in $pipelines) {
                $output = [PSCustomObject]@{
                    Id          = $pipeline.id
                    Name        = $pipeline.displayName
                    Description = $pipeline.description
                }

                if ($IncludeDefinition) {
                    # Get pipeline definition
                    $pipelineApiUrl = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/dataPipelines/$($pipeline.id)/definition"
                    Write-Verbose "Fetching definition for pipeline: $($pipeline.displayName)"
                    
                    try {
                        $definition = Invoke-RestMethod -Uri $pipelineApiUrl -Method Get -Headers $headers
                        $output | Add-Member -NotePropertyName "Definition" -NotePropertyValue ($definition | ConvertTo-Json -Depth 10)
                    }
                    catch {
                        Write-Warning "Could not retrieve definition for pipeline: $($pipeline.displayName)"
                        $output | Add-Member -NotePropertyName "Definition" -NotePropertyValue "Error retrieving definition"
                    }
                }

                $output
            }

            $results | Format-Table -AutoSize
            return $results
        } else {
            Write-Host "No pipelines found in workspace: $WorkspaceId" -ForegroundColor Yellow
        }
    } else {
        Write-Warning "No items returned from the API. The workspace may not exist or you may not have access."
    }
}
catch {
    Write-Error "An error occurred while retrieving pipelines: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        Write-Error "Status Code: $($_.Exception.Response.StatusCode.value__)"
    }
    exit 1
}
