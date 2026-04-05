<#
.SYNOPSIS
    Triggers execution of a Fabric Data Pipeline.

.DESCRIPTION
    This script starts a data pipeline run in Microsoft Fabric, optionally passing
    parameters to the pipeline execution.

.PARAMETER WorkspaceId
    The ID (GUID) of the Fabric workspace containing the pipeline.

.PARAMETER PipelineId
    The ID (GUID) of the data pipeline to execute.

.PARAMETER Parameters
    Optional hashtable of parameters to pass to the pipeline.

.PARAMETER Wait
    If specified, waits for the pipeline run to complete and returns the final status.

.PARAMETER TimeoutSeconds
    Maximum time to wait for pipeline completion (default: 3600 seconds / 1 hour).

.EXAMPLE
    .\Invoke-FabricPipeline.ps1 -WorkspaceId "xxx" -PipelineId "yyy"
    
    Triggers the pipeline and returns immediately with the run ID.

.EXAMPLE
    .\Invoke-FabricPipeline.ps1 -WorkspaceId "xxx" -PipelineId "yyy" -Wait
    
    Triggers the pipeline and waits for completion.

.EXAMPLE
    $params = @{ StartDate = "2024-01-01"; EndDate = "2024-12-31" }
    .\Invoke-FabricPipeline.ps1 -WorkspaceId "xxx" -PipelineId "yyy" -Parameters $params
    
    Triggers the pipeline with parameters.

.NOTES
    Author: Claudio Da Silva
    Requires: Az.Accounts module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$PipelineId,

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters,

    [Parameter(Mandatory = $false)]
    [switch]$Wait,

    [Parameter(Mandatory = $false)]
    [int]$TimeoutSeconds = 3600
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

    # Build request body
    $body = @{}
    if ($Parameters -and $Parameters.Count -gt 0) {
        $body.parameters = $Parameters
    }

    $jsonBody = $body | ConvertTo-Json -Depth 10

    # Define the API URL to trigger pipeline
    $apiUrl = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items/$PipelineId/jobs/instances?jobType=Pipeline"
    Write-Verbose "API URL: $apiUrl"

    # Define the request headers
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }

    # Trigger the pipeline
    Write-Host "Triggering pipeline execution..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $jsonBody

    $runId = $response.id
    Write-Host "Pipeline triggered successfully!" -ForegroundColor Green
    Write-Host "Run ID: $runId" -ForegroundColor Yellow
    Write-Host ""

    if ($Wait) {
        Write-Host "Waiting for pipeline to complete (timeout: $TimeoutSeconds seconds)..." -ForegroundColor Cyan
        $startTime = Get-Date
        $statusUrl = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items/$PipelineId/jobs/instances/$runId"

        do {
            Start-Sleep -Seconds 10
            $statusResponse = Invoke-RestMethod -Uri $statusUrl -Method Get -Headers $headers
            
            $elapsedSeconds = ((Get-Date) - $startTime).TotalSeconds
            $status = $statusResponse.status
            
            Write-Host "Status: $status | Elapsed: $([math]::Round($elapsedSeconds))s" -ForegroundColor Yellow

            if ($elapsedSeconds -gt $TimeoutSeconds) {
                Write-Warning "Pipeline execution exceeded timeout of $TimeoutSeconds seconds"
                break
            }

        } while ($status -in @("NotStarted", "InProgress", "Queued"))

        Write-Host ""
        if ($status -eq "Completed") {
            Write-Host "Pipeline completed successfully!" -ForegroundColor Green
        } elseif ($status -eq "Failed") {
            Write-Error "Pipeline execution failed!"
        } elseif ($status -eq "Cancelled") {
            Write-Warning "Pipeline execution was cancelled"
        }

        return $statusResponse
    }

    return $response
}
catch {
    Write-Error "An error occurred while triggering pipeline: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        Write-Error "Status Code: $($_.Exception.Response.StatusCode.value__)"
    }
    exit 1
}
