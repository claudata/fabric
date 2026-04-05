# Example: Working with Fabric Data Pipelines

This example demonstrates how to manage and execute Fabric Data Pipelines using PowerShell.

## Prerequisites

- Azure PowerShell module installed
- Authenticated with `Connect-AzAccount`
- Workspace access with pipeline execution permissions

## List All Pipelines

```powershell
# Connect to Azure
Connect-AzAccount

# Set your workspace ID
$workspaceId = "12345678-1234-1234-1234-123456789012"

# List all pipelines
.\scripts\powershell\data-pipeline\Get-FabricDataPipeline.ps1 -WorkspaceId $workspaceId
```

Example output:
```
Successfully retrieved 3 pipeline(s)

Id          Name                    Description
--          ----                    -----------
abc123...   Daily_Sales_Load        Load sales data daily
def456...   Customer_ETL            Customer data processing
ghi789...   Warehouse_Sync          Sync lakehouse to warehouse
```

## Trigger a Pipeline

```powershell
# Simple execution
.\scripts\powershell\data-pipeline\Invoke-FabricPipeline.ps1 `
    -WorkspaceId $workspaceId `
    -PipelineId "abc123-def456-ghi789"
```

## Trigger Pipeline with Parameters

```powershell
# Define parameters
$params = @{
    StartDate = "2024-01-01"
    EndDate = "2024-12-31"
    SourceTable = "sales_raw"
    TargetTable = "sales_processed"
}

# Execute with parameters
.\scripts\powershell\data-pipeline\Invoke-FabricPipeline.ps1 `
    -WorkspaceId $workspaceId `
    -PipelineId "abc123-def456-ghi789" `
    -Parameters $params
```

## Wait for Pipeline Completion

```powershell
# Execute and wait for completion
$result = .\scripts\powershell\data-pipeline\Invoke-FabricPipeline.ps1 `
    -WorkspaceId $workspaceId `
    -PipelineId "abc123-def456-ghi789" `
    -Wait `
    -TimeoutSeconds 1800  # 30 minutes

if ($result.status -eq "Completed") {
    Write-Host "Pipeline succeeded!" -ForegroundColor Green
} else {
    Write-Host "Pipeline failed or timed out" -ForegroundColor Red
}
```

## Monitor Pipeline Runs

```powershell
# Get recent runs for a specific pipeline
.\scripts\powershell\data-pipeline\Get-FabricPipelineRuns.ps1 `
    -WorkspaceId $workspaceId `
    -PipelineId "abc123-def456-ghi789" `
    -Top 10
```

## Filter by Status

```powershell
# Get all failed runs in the workspace
.\scripts\powershell\data-pipeline\Get-FabricPipelineRuns.ps1 `
    -WorkspaceId $workspaceId `
    -Status Failed `
    -Top 50
```

Example output:
```
Querying pipeline runs...

Found 2 pipeline run(s)

PipelineName      Status  StartTime            Duration
------------      ------  ---------            --------
Daily_Sales_Load  Failed  2024-01-15 08:00:00  00:05:23
Customer_ETL      Failed  2024-01-14 09:30:00  00:03:45
```

## Scheduled Execution Pattern

```powershell
# Script to run as scheduled task
param(
    [string]$WorkspaceId = "your-workspace-id",
    [string]$PipelineId = "your-pipeline-id"
)

try {
    # Connect using service principal
    $appId = $env:AZURE_CLIENT_ID
    $secret = $env:AZURE_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
    $tenantId = $env:AZURE_TENANT_ID
    
    $credential = New-Object System.Management.Automation.PSCredential($appId, $secret)
    Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId
    
    # Trigger pipeline
    $result = .\scripts\powershell\data-pipeline\Invoke-FabricPipeline.ps1 `
        -WorkspaceId $WorkspaceId `
        -PipelineId $PipelineId `
        -Wait `
        -TimeoutSeconds 3600
    
    # Log result
    $logEntry = @{
        Timestamp = Get-Date
        Status = $result.status
        RunId = $result.id
    }
    
    $logEntry | ConvertTo-Json | Out-File -Append "pipeline-execution-log.json"
    
    if ($result.status -ne "Completed") {
        # Send alert (implement your notification logic)
        throw "Pipeline execution failed"
    }
}
catch {
    Write-Error "Pipeline execution encountered an error: $_"
    # Send alert/notification
    exit 1
}
```

## Monitor All Pipelines in Workspace

```powershell
# Get all pipelines
$pipelines = .\scripts\powershell\data-pipeline\Get-FabricDataPipeline.ps1 `
    -WorkspaceId $workspaceId

# Check recent runs for each
foreach ($pipeline in $pipelines) {
    Write-Host "`nPipeline: $($pipeline.Name)" -ForegroundColor Cyan
    
    $runs = .\scripts\powershell\data-pipeline\Get-FabricPipelineRuns.ps1 `
        -WorkspaceId $workspaceId `
        -PipelineId $pipeline.Id `
        -Top 5
    
    $failedRuns = $runs | Where-Object { $_.Status -eq "Failed" }
    
    if ($failedRuns.Count -gt 0) {
        Write-Host "  ⚠ $($failedRuns.Count) failed run(s) found" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ No recent failures" -ForegroundColor Green
    }
}
```

## Parallel Pipeline Execution

```powershell
# Execute multiple pipelines in parallel
$pipelineIds = @(
    "pipeline-id-1",
    "pipeline-id-2",
    "pipeline-id-3"
)

$jobs = foreach ($pipelineId in $pipelineIds) {
    Start-Job -ScriptBlock {
        param($wsId, $pId)
        
        .\scripts\powershell\data-pipeline\Invoke-FabricPipeline.ps1 `
            -WorkspaceId $wsId `
            -PipelineId $pId `
            -Wait
            
    } -ArgumentList $workspaceId, $pipelineId
}

# Wait for all to complete
$results = $jobs | Wait-Job | Receive-Job

# Show results
$results | Format-Table -AutoSize
```

## See Also

- [Warehouse Management Examples](warehouse-management.md)
- [Warehouse Data Loading](warehouse-loading.md)
- [Fabric REST API Documentation](https://learn.microsoft.com/rest/api/fabric/)
