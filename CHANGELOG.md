# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Data Warehouse PowerShell Scripts**:
  - `Get-FabricWarehouse.ps1` - List warehouses with connection strings
  - `Get-FabricWarehouseMetadata.ps1` - Generate metadata queries
- **Data Pipeline PowerShell Scripts**:
  - `Get-FabricDataPipeline.ps1` - List pipelines with definitions
  - `Invoke-FabricPipeline.ps1` - Trigger and monitor pipeline execution
  - `Get-FabricPipelineRuns.ps1` - Query pipeline execution history
- **PySpark Warehouse Utilities**:
  - `lakehouse_to_warehouse_sync.py` - Sync lakehouse to warehouse
  - `warehouse_bulk_loader.py` - High-performance data loading
- **SQL Warehouse Scripts**:
  - `warehouse_query_performance.sql` - Performance monitoring
  - `warehouse_storage_analysis.sql` - Storage and table analysis
  - `warehouse_data_quality_checks.sql` - Data quality validation
- **Examples**:
  - `warehouse-management.md` - Warehouse management examples
  - `pipeline-examples.md` - Pipeline orchestration patterns
  - `warehouse-loading.md` - Data loading best practices
- Comprehensive README.md with usage examples and documentation
- MIT License
- Contributing guidelines (CONTRIBUTING.md)
- .gitignore file for PowerShell, Python, and common artifacts
- Proper folder structure (scripts/powershell, examples, docs)

### Changed
- Reorganized repository structure for better maintainability
- Renamed `list_mpe` to `Get-FabricManagedPrivateEndpoints.ps1`
- Enhanced PowerShell script with:
  - Proper comment-based help
  - Parameter validation
  - Error handling with try/catch
  - Verbose output support
  - Multiple output format options (Table/List)
  - Pipeline-friendly output
- Updated README with complete documentation of all Data Warehouse and Pipeline utilities

### Removed
- Azure Static Web Apps workflow (not applicable to this project)
- Empty `spark` file
- Old `fabric/` directory structure

## [1.0.0] - 2025 (Initial Release)

### Added
- Initial version with basic managed private endpoint listing script
- Basic README

---

## Legend

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes
