# Microsoft Fabric Automation Toolkit

A collection of scripts, tools, and examples for automating Microsoft Fabric operations using PowerShell, Python, and REST APIs.

## 🎯 Overview

This repository provides ready-to-use automation scripts for Microsoft Fabric, including:
- **Data Warehouse**: Create, manage, and query Fabric Data Warehouses
- **Data Pipelines**: Trigger, monitor, and manage pipeline executions
- **Lakehouse to Warehouse**: Sync data between lakehouses and warehouses
- **Managed Private Endpoints**: List and manage network connections
- **Workspace Operations**: Inventory and manage workspace resources
- **Data Quality**: SQL scripts for validation and monitoring

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Scripts](#scripts)
  - [PySpark Utilities](#pyspark-utilities)
  - [SQL Scripts](#sql-scripts)
  - [PowerShell Scripts](#powershell-scripts)
- [Usage Examples](#usage-examples)
- [Authentication](#authentication)
- [Contributing](#contributing)
- [License](#license)

## 🔧 Prerequisites

### Required Software
- PowerShell 7.0 or later (recommended)
- Azure PowerShell Module (`Az.Accounts`)
- Valid Microsoft Fabric workspace access

### Azure Modules
```powershell
# Install required Azure modules
Install-Module -Name Az.Accounts -Scope CurrentUser -Force
```

### Permissions
- Fabric Administrator or Workspace Admin role
- Azure AD authentication enabled
- Appropriate RBAC permissions for Fabric API access

## 📦 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/claudata/fabric.git
   cd fabric
   ```

2. **Authenticate with Azure:**
   ```powershell
   Connect-AzAccount
   ```

3. **Verify access to Fabric:**
   ```powershell
   Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com"
   ```

## 📜 Scripts

### PData Warehouse Management

**Get-FabricWarehouse.ps1**
- Lists all warehouses in a workspace
- Optionally includes SQL connection strings
- Location: `scripts/powershell/warehouse/`

```powershell
.\scripts\powershell\warehouse\Get-FabricWarehouse.ps1 `
    -WorkspaceId "xxx" `
    -IncludeConnectionString
```

**Get-FabricWarehouseMetadata.ps1**
- Generates SQL queries to retrieve warehouse metadata
- Supports tables, schemas, views, columns, stored procedures
- Location: `scripts/powershell/warehouse/`

#### Data Pipeline Management

**Get-FabricDataPipeline.ps1**
- Lists all pipelines in a workspace
- Optionally includes pipeline definitions (JSON)
- Location: `scripts/powershell/data-pipeline/`

```powershell
.\scripts\powershell\data-pipeline\Get-FabricDataPipeline.ps1 `
    -WorkspaceId "xxx"
```

**Invoke-FabricPipeline.ps1**
- Triggers pipeline execution
- Supports parameters and wait for completion
- Location: `scripts/powershell/data-pipeline/`

```powershell
.\scripts\powershell\data-pipeline\Invoke-FabricPipeline.ps1 `
    -WorkspaceId "xxx" `
    -PipelineId "yyy" `
    -Wait
```

**Get-FabricPipelineRuns.ps1**
- Retrieves pipeline execution history
- Filter by status (Completed, Failed, InProgress)
- Location: `scripts/powershell/data-pipeline/`

#### Network Management

**Get-FabricManagedPrivateEndpoints.ps1**
- Lists all managed private endpoints in a workspace
- Display in Table or List format
- Location: `scripts/powershell/`

```powershell
.\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 `
    -WorkspaceId "xxx" `
    -OutputFormat Table
```

### PySpark Utilities

#### Warehouse Data Integration

**lakehouse_to_warehouse_sync.py**
- Sync data from lakehouse Delta tables to warehouse
- Supports overwrite, append, and merge modes
- Bulk sync multiple tables
- Location: `scripts/pyspark/warehouse/`

```python
from lakehouse_to_warehouse_sync import LakehouseWarehouseSync

sync = LakehouseWarehouseSync(warehouse_name="MyWarehouse")
result = sync.sync_table(
    lakehouse_table="sales_data",
    warehouse_schema="dbo",
    mode="overwrite"
)
```

**warehouse_bulk_loader.py**
- High-performance data loading using COPY INTO pattern
- Supports Parquet, Delta, and CSV sources
- Optimized for large datasets
- Location: `scripts/pyspark/warehouse/`

```python
from warehouse_bulk_loader import WarehouseBulkLoader

loader = WarehouseBulkLoader(warehouse_name="MyWarehouse")
result = loader.load_from_parquet(
    source_path="Files/data/*.parquet",
    target_schema="dbo",
    target_table="fact_sales",
    mode="append"
)
```

### SQL Scripts

#### Warehouse Performance & Monitoring

**warehouse_query_performance.sql**
- Monitor currently running queries
- Identify blocking sessions
- Analyze wait statistics
- Detect long-running queries
- Location: `scripts/sql/warehouse/`

**warehouse_storage_analysis.sql**
- Table row counts and sizes
- Schema-level storage summary
- Identify empty or undersized tables
- Column statistics freshness
- Location: `scripts/sql/warehouse/`

**warehouse_data_quality_checks.sql**
- NULL value analysis
- Duplicate detection
- Referential integrity checks
- Data range validation
- Comprehensive quality reports
- Location: `scripts/sql/warehouse/`powershell
.\scripts\powershell\Get-FabricManagedPrivateEndpoints.ps1 -WorkspaceId "12345678-1234-1234-1234-123456789012"
```

## 💡 Usage Examples

### Finding Your Workspace ID
You can find your workspace ID in the Fabric portal URL:
```
https://app.fabric.microsoft.com/groups/{workspace-id}/...
```

### Example 1: List Warehouses and Trigger Pipeline

```powershell
# Connect to Azure
Connect-AzAccount

$workspaceId = "your-workspace-id"

# List all warehouses
$warehouses = .\scripts\powershell\warehouse\Get-FabricWarehouse.ps1 `
    -WorkspaceId $workspaceId

# Trigger a data pipeline
.\scripts\powershell\data-pipeline\Invoke-FabricPipeline.ps1 `
    -WorkspaceId $workspaceId `
    -PipelineId "your-pipeline-id" `
    -Wait
```

### Example 2: Sync Lakehouse to Warehouse

```python
# In a Fabric Notebook
from lakehouse_to_warehouse_sync import LakehouseWarehouseSync

sync = LakehouseWarehouseSync(warehouse_name="MyWarehouse")

# Sync multiple tables
tables = [
    {'source': 'fact_sales', 'target_schema': 'dbo', 'mode': 'overwrite'},
    {'source': 'dim_customer', 'target_schema': 'dbo', 'mode': 'overwrite'}
]

results = sync.bulk_sync(tables)
```

### Example 3: Monitor Pipeline Runs

```powershell
# Get failed pipeline runs from last 24 hours
.\scripts\powershell\data-pipeline\Get-FabricPipelineRuns.ps1 `
    -WorkspaceId $workspaceId `
    -Status Failed `
    -Top 50
```

### Example 4: Check Warehouse Data Quality

```sql
-- Run in Fabric Data Warehouse SQL endpoint
-- Check for NULL values in critical columns
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS null_names,
    SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS null_emails
FROM dbo.customers;
```

For more detailed examples, see:
- [Warehouse Management Examples](examples/warehouse-management.md)
- [Pipeline Examples](examples/pipeline-examples.md)
- [Warehouse Loading Examples](examples/warehouse-loading.md)

## 🔐 Authentication

### Using Service Principal (CI/CD)
```powershell
$clientId = "your-client-id"
$clientSecret = "your-client-secret" | ConvertTo-SecureString -AsPlainText -Force
$tenantId = "your-tenant-id"

$credential = New-Object System.Management.Automation.PSCredential($clientId, $clientSecret)
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId
```

### Using Managed Identity (Azure Automation)
```powershell
Connect-AzAccount -Identity
```

## 🗂️ Repository Structure

```
fabric/
├── scripts/
│   ├── powershell/
│   │   ├── warehouse/                    # Data Warehouse scripts
│   │   │   ├── Get-FabricWarehouse.ps1
│   │   │   └── Get-FabricWarehouseMetadata.ps1
│   │   ├── data-pipeline/                # Data Pipeline scripts
│   │   │   ├── Get-FabricDataPipeline.ps1
│   │   │   ├── Invoke-FabricPipeline.ps1
│   │   │   └── Get-FabricPipelineRuns.ps1
│   │   └── Get-FabricManagedPrivateEndpoints.ps1
│   ├── pyspark/
│   │   └── warehouse/                    # Warehouse integration
│   │       ├── lakehouse_to_warehouse_sync.py
│   │       └── warehouse_bulk_loader.py
│   └── sql/
│       └── warehouse/                    # SQL utilities
│           ├── warehouse_query_performance.sql
│           ├── warehouse_storage_analysis.sql
│           └── warehouse_data_quality_checks.sql
├── examples/                             # Usage examples
│   ├── warehouse-management.md
│   ├── pipeline-examples.md
│   ├── warehouse-loading.md
│   └── list-managed-endpoints.md
├── docs/                                 # Documentation
│   └── GETTING-STARTED.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Coding Standards
- Follow PowerShell best practices and style guidelines
- Include comment-based help for all scripts
- Add error handling and input validation
- Write descriptive commit messages

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Useful Links

- [Microsoft Fabric Documentation](https://learn.microsoft.com/fabric/)
- [Fabric REST API Reference](https://learn.microsoft.com/rest/api/fabric/)
- [PowerShell Documentation](https://learn.microsoft.com/powershell/)
- [Azure PowerShell Documentation](https://learn.microsoft.com/powershell/azure/)

## 📧 Support

For issues, questions, or contributions:
- Open an [issue](https://github.com/claudata/fabric/issues)
- Submit a [pull request](https://github.com/claudata/fabric/pulls)

## 🎓 Additional Resources

### Fabric API Examples
- [Authentication with Fabric APIs](https://learn.microsoft.com/fabric/admin/metadata-scanning-overview)
- [Managing Workspaces](https://learn.microsoft.com/fabric/admin/admin-overview)

---

**Note:** This repository is not officially affiliated with Microsoft. It's a community-driven project to help automate Fabric operations.
