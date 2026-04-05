<#
.SYNOPSIS
    Retrieves execution history for Fabric Data Pipelines.

.DESCRIPTION
    This script retrieves pipeline run history, including status, duration, and error details
    for a specific pipeline or all pipelines in a workspace.

.PARAMETER WorkspaceId
    The ID (GUID) of the Fabric workspace.

.PARAMETER PipelineId
    Optional. The ID (GUID) of a specific pipeline. If not provided, retrieves runs for all pipelines.

.PARAMETER Status
    Optional. Filter by run status: All, Completed, Failed, InProgress, Cancelled

.PARAMETER Top
    Maximum number of runs to retrieve (default: 20).

.EXAMPLE
    .\Get-FabricPipelineRuns.ps1 -WorkspaceId "xxx" -PipelineId "yyy"
    
    Gets recent runs for a specific pipeline.

.EXAMPLE
    .\Get-FabricPipelineRuns.ps1 -WorkspaceId "xxx" -Status Failed
    
    Gets all failed pipeline runs in the workspace.

.NOTES
    Author: Claudio Da Silva
    Requires: Az.Accounts module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceId,

    [Parameter(Mandatory = $false)]
    [string]$PipelineId,

    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'Completed', 'Failed', 'InProgress', 'Cancelled', 'Queued')]
    [string]$Status = 'All',

    [Parameter(Mandatory = $false)]
    [int]$Top = 20
)

$ErrorActionPreference = 'Stop'

try {
    # Verify Az.Accounts module
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        throw "Az.Accounts module is not installed. Please install it using: Install-Module -Name Az.Accounts"
    }

    Write-Verbose "Retrieving access token for Fabric API..."
    $token = (Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com").Token

    if ([string]::IsNullOrEmpty($token)) {
        throw "Failed to retrieve access token. Please ensure you are authenticated with Connect-AzAccount."
    }

    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }

    # Get pipeline(s) to query
    $pipelinesToQuery = @()
    
    if ($PipelineId) {
        $pipelinesToQuery += @{ Id = $PipelineId; Name = "Specified Pipeline" }
    } else {
        # Get all pipelines in workspace
        $itemsUrl = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items"
        $items = Invoke-RestMethod -Uri $itemsUrl -Method Get -Headers $headers
        $pipelines = $items.value | Where-Object { $_.type -eq "DataPipeline" }
        $pipelinesToQuery = $pipelines | ForEach-Object { @{ Id = $_.id; Name = $_.displayName } }
    }

    if ($pipelinesToQuery.Count -eq 0) {
        Write-Warning "No pipelines found to query"
        return
    }

    Write-Host "Querying pipeline runs..." -ForegroundColor Cyan
    $allRuns = @()

    foreach ($pipeline in $pipelinesToQuery) {
        $runsUrl = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items/$($pipeline.Id)/jobs/instances?top=$Top"
        Write-Verbose "Fetching runs for pipeline: $($pipeline.Name)"
        
        try {
            $runsResponse = Invoke-RestMethod -Uri $runsUrl -Method Get -Headers $headers
            
            foreach ($run in $runsResponse.value) {
                $runInfo = [PSCustomObject]@{
                    PipelineName  = $pipeline.Name
                    PipelineId    = $pipeline.Id
                    RunId         = $run.id
                    Status        = $run.status
                    StartTime     = $run.invokeTime
                    EndTime       = $run.endTime
                    Duration      = if ($run.endTime) { 
                        ([datetime]$run.endTime - [datetime]$run.invokeTime).ToString("hh\:mm\:ss") 
                    } else { "Running" }
                    JobType       = $run.jobType
                }

                # Filter by status if specified
                if ($Status -eq 'All' -or $run.status -eq $Status) {
                    $allRuns += $runInfo
                }
            }
        }
        catch {
            Write-Warning "Could not retrieve runs for pipeline: $($pipeline.Name)"
        }
    }

    if ($allRuns.Count -gt 0) {
        Write-Host "`nFound $($allRuns.Count) pipeline run(s)" -ForegroundColor Green
        Write-Host ""
        $allRuns | Sort-Object StartTime -Descending | Format-Table -AutoSize
        return $allRuns
    } else {
        Write-Host "No pipeline runs found matching criteria" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "An error occurred while retrieving pipeline runs: $($_.Exception.Message)"
    exit 1
}
