# Example: Loading Data into Fabric Data Warehouse

This example demonstrates various methods for loading data from Lakehouse to Data Warehouse using PySpark.

## Prerequisites

- Fabric Notebook or Spark environment
- Access to Lakehouse and Data Warehouse
- Appropriate permissions for data movement

## Method 1: Sync Lakehouse Table to Warehouse

```python
# Import the sync utility
from lakehouse_to_warehouse_sync import LakehouseWarehouseSync

# Initialize with your warehouse name
sync = LakehouseWarehouseSync(warehouse_name="MyWarehouse")

# Sync a single table (overwrite mode)
result = sync.sync_table(
    lakehouse_table="sales_data",
    warehouse_schema="dbo",
    mode="overwrite"
)

print(result)
```

Expected output:
```
Starting sync: sales_data -> dbo.sales_data
Mode: overwrite
Read 1,500,000 rows from lakehouse
✓ Sync completed in 45.23 seconds

{
  "status": "success",
  "source_table": "sales_data",
  "target_table": "dbo.sales_data",
  "rows_synced": 1500000,
  "duration_seconds": 45.23,
  "mode": "overwrite"
}
```

## Method 2: Bulk Sync Multiple Tables

```python
from lakehouse_to_warehouse_sync import LakehouseWarehouseSync

sync = LakehouseWarehouseSync(warehouse_name="MyWarehouse")

# Define multiple table mappings
table_mappings = [
    {
        'source': 'fact_sales',
        'target_schema': 'dbo',
        'mode': 'overwrite'
    },
    {
        'source': 'dim_customer',
        'target_schema': 'dbo',
        'mode': 'overwrite'
    },
    {
        'source': 'dim_product',
        'target_schema': 'dbo',
        'mode': 'append'
    }
]

# Execute bulk sync
results = sync.bulk_sync(table_mappings)

# Check results
for result in results:
    if result['status'] == 'success':
        print(f"✓ {result['source_table']} - {result['rows_synced']:,} rows")
    else:
        print(f"✗ {result['source_table']} - Error: {result['error']}")
```

## Method 3: Load from Parquet Files

```python
from warehouse_bulk_loader import WarehouseBulkLoader

loader = WarehouseBulkLoader(warehouse_name="MyWarehouse")

# Load from Parquet files in lakehouse
result = loader.load_from_parquet(
    source_path="Files/exports/sales/*.parquet",
    target_schema="dbo",
    target_table="fact_sales",
    mode="append"
)

print(f"Loaded {result['rows_loaded']:,} rows in {result['duration_seconds']:.2f} seconds")
print(f"Throughput: {result['throughput_rows_per_sec']:,.0f} rows/second")
```

## Method 4: Incremental Load from Delta Table

```python
from warehouse_bulk_loader import WarehouseBulkLoader
from datetime import datetime, timedelta

loader = WarehouseBulkLoader(warehouse_name="MyWarehouse")

# Get yesterday's date for incremental load
yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')

# Load only new/changed records
result = loader.load_from_delta(
    delta_table="sales_transactions",
    target_schema="dbo",
    target_table="fact_sales",
    mode="append",
    filter_condition=f"transaction_date >= '{yesterday}'"
)

print(result)
```

## Method 5: Load CSV Files

```python
from warehouse_bulk_loader import WarehouseBulkLoader

loader = WarehouseBulkLoader(warehouse_name="MyWarehouse")

# Load CSV files
result = loader.load_from_csv(
    csv_path="Files/imports/*.csv",
    target_schema="staging",
    target_table="customer_import",
    has_header=True,
    delimiter=",",
    mode="overwrite"
)
```

## Method 6: Create Warehouse Table from Lakehouse Schema

```python
from lakehouse_to_warehouse_sync import LakehouseWarehouseSync

sync = LakehouseWarehouseSync(warehouse_name="MyWarehouse")

# Generate CREATE TABLE statement
create_sql = sync.create_warehouse_table_from_lakehouse(
    lakehouse_table="product_catalog",
    warehouse_schema="dbo",
    warehouse_table="dim_product"
)

print("Execute this SQL in your warehouse:")
print(create_sql)
```

Output:
```sql
CREATE TABLE [dbo].[dim_product] (
    [product_id] INT NOT NULL,
    [product_name] VARCHAR(MAX) NULL,
    [category] VARCHAR(MAX) NULL,
    [price] DECIMAL(18,2) NULL,
    [created_date] DATETIME2 NULL
);
```

## Complete End-to-End Example

```python
from lakehouse_to_warehouse_sync import LakehouseWarehouseSync
from warehouse_bulk_loader import WarehouseBulkLoader
from datetime import datetime

print("=== Lakehouse to Warehouse Data Loading ===")
print(f"Start time: {datetime.now()}")

# Initialize utilities
sync = LakehouseWarehouseSync(warehouse_name="SalesWarehouse")
loader = WarehouseBulkLoader(warehouse_name="SalesWarehouse")

try:
    # Step 1: Load dimension tables (full refresh)
    print("\n[1/4] Loading dimension tables...")
    dim_tables = [
        {'source': 'dim_customer', 'target_schema': 'dbo', 'mode': 'overwrite'},
        {'source': 'dim_product', 'target_schema': 'dbo', 'mode': 'overwrite'},
        {'source': 'dim_date', 'target_schema': 'dbo', 'mode': 'overwrite'}
    ]
    
    dim_results = sync.bulk_sync(dim_tables)
    
    # Step 2: Load fact table (incremental)
    print("\n[2/4] Loading fact table (incremental)...")
    yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')
    
    fact_result = loader.load_from_delta(
        delta_table="fact_sales",
        target_schema="dbo",
        target_table="fact_sales",
        mode="append",
        filter_condition=f"sale_date >= '{yesterday}'"
    )
    
    # Step 3: Load staging data from CSV
    print("\n[3/4] Loading staging data...")
    staging_result = loader.load_from_csv(
        csv_path="Files/imports/new_products.csv",
        target_schema="staging",
        target_table="product_staging",
        has_header=True,
        mode="overwrite"
    )
    
    # Step 4: Summary
    print("\n[4/4] Load Summary:")
    print("=" * 60)
    
    total_rows = sum(r.get('rows_synced', 0) for r in dim_results)
    total_rows += fact_result.get('rows_loaded', 0)
    total_rows += staging_result.get('rows_loaded', 0)
    
    print(f"Total rows loaded: {total_rows:,}")
    print(f"Dimension tables: {len(dim_results)}")
    print(f"Fact table records: {fact_result.get('rows_loaded', 0):,}")
    print(f"End time: {datetime.now()}")
    print("✓ All data loaded successfully!")
    
except Exception as e:
    print(f"✗ Error during data loading: {str(e)}")
    raise
```

## Best Practices

1. **Use appropriate modes**:
   - `overwrite` for dimension tables (full refresh)
   - `append` for fact tables (incremental)

2. **Filter for incremental loads**:
   - Use date partitions or watermarks
   - Avoid reprocessing historical data

3. **Monitor performance**:
   - Track throughput (rows/second)
   - Optimize file sizes (target 100MB-1GB Parquet files)

4. **Error handling**:
   - Always wrap in try/catch
   - Log results for auditing
   - Implement retry logic for transient failures

5. **Schedule appropriately**:
   - Run dimension loads before facts
   - Use pipeline orchestration for dependencies

## See Also

- [Pipeline Examples](pipeline-examples.md)
- [Warehouse Management](warehouse-management.md)
- [SQL Quality Checks](../scripts/sql/warehouse/)
