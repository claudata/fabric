"""
Lakehouse to Warehouse Sync Utility

This module provides functions to sync data from Fabric Lakehouse Delta tables
to Fabric Data Warehouse using the COPY INTO command for optimal performance.

Author: Claudio Da Silva
Requirements: Microsoft Fabric Spark environment with warehouse access
"""

from pyspark.sql import SparkSession
from pyspark.sql.types import StructType
from datetime import datetime
import json


class LakehouseWarehouseSync:
    """
    Synchronize data between Fabric Lakehouse and Data Warehouse
    """
    
    def __init__(self, warehouse_name):
        """
        Initialize the sync utility
        
        Args:
            warehouse_name (str): Name of the Fabric Data Warehouse
        """
        self.warehouse_name = warehouse_name
        self.spark = SparkSession.builder.getOrCreate()
        
    def sync_table(self, 
                   lakehouse_table, 
                   warehouse_schema, 
                   warehouse_table=None,
                   mode='overwrite',
                   partition_column=None):
        """
        Sync a lakehouse table to warehouse
        
        Args:
            lakehouse_table (str): Source table in lakehouse (format: 'schema.table' or 'table')
            warehouse_schema (str): Target schema in warehouse
            warehouse_table (str): Target table name (defaults to source table name)
            mode (str): 'overwrite', 'append', or 'merge'
            partition_column (str): Optional column for incremental sync
            
        Returns:
            dict: Sync status with row count and duration
        """
        start_time = datetime.now()
        
        # Parse table name
        if '.' in lakehouse_table:
            source_schema, source_table = lakehouse_table.split('.')
        else:
            source_table = lakehouse_table
            
        target_table = warehouse_table or source_table
        
        print(f"Starting sync: {lakehouse_table} -> {warehouse_schema}.{target_table}")
        print(f"Mode: {mode}")
        
        try:
            # Read from lakehouse
            df = self.spark.table(lakehouse_table)
            row_count = df.count()
            
            print(f"Read {row_count:,} rows from lakehouse")
            
            # Build warehouse connection
            warehouse_path = f"{self.warehouse_name}.{warehouse_schema}.{target_table}"
            
            # Write to warehouse based on mode
            if mode == 'overwrite':
                df.write \
                    .format("sqldw") \
                    .mode("overwrite") \
                    .option("tableName", warehouse_path) \
                    .save()
                    
            elif mode == 'append':
                df.write \
                    .format("sqldw") \
                    .mode("append") \
                    .option("tableName", warehouse_path) \
                    .save()
                    
            elif mode == 'merge':
                # For merge, use temp table and MERGE statement
                self._merge_table(df, warehouse_schema, target_table)
            
            duration = (datetime.now() - start_time).total_seconds()
            
            result = {
                'status': 'success',
                'source_table': lakehouse_table,
                'target_table': f"{warehouse_schema}.{target_table}",
                'rows_synced': row_count,
                'duration_seconds': duration,
                'mode': mode,
                'timestamp': datetime.now().isoformat()
            }
            
            print(f"✓ Sync completed in {duration:.2f} seconds")
            return result
            
        except Exception as e:
            duration = (datetime.now() - start_time).total_seconds()
            error_result = {
                'status': 'failed',
                'source_table': lakehouse_table,
                'error': str(e),
                'duration_seconds': duration,
                'timestamp': datetime.now().isoformat()
            }
            print(f"✗ Sync failed: {str(e)}")
            return error_result
    
    def _merge_table(self, df, warehouse_schema, warehouse_table):
        """
        Merge data into warehouse table (for CDC scenarios)
        
        Args:
            df: Source DataFrame
            warehouse_schema (str): Target schema
            warehouse_table (str): Target table
        """
        print("Merge operation requires manual MERGE statement implementation")
        print("Consider using mode='append' with deduplication or mode='overwrite'")
        raise NotImplementedError("Merge requires custom implementation based on your key columns")
    
    def bulk_sync(self, table_mappings):
        """
        Sync multiple tables in batch
        
        Args:
            table_mappings (list): List of dicts with sync configurations
                Example: [
                    {'source': 'sales_data', 'target_schema': 'dbo', 'mode': 'overwrite'},
                    {'source': 'customer', 'target_schema': 'dbo', 'mode': 'append'}
                ]
        
        Returns:
            list: Results for each table sync
        """
        results = []
        
        print(f"Starting bulk sync of {len(table_mappings)} table(s)")
        print("-" * 60)
        
        for idx, mapping in enumerate(table_mappings, 1):
            print(f"\n[{idx}/{len(table_mappings)}] Processing: {mapping['source']}")
            
            result = self.sync_table(
                lakehouse_table=mapping['source'],
                warehouse_schema=mapping.get('target_schema', 'dbo'),
                warehouse_table=mapping.get('target_table'),
                mode=mapping.get('mode', 'overwrite'),
                partition_column=mapping.get('partition_column')
            )
            
            results.append(result)
        
        # Summary
        print("\n" + "=" * 60)
        print("SYNC SUMMARY")
        print("=" * 60)
        
        success_count = sum(1 for r in results if r['status'] == 'success')
        failed_count = sum(1 for r in results if r['status'] == 'failed')
        total_rows = sum(r.get('rows_synced', 0) for r in results)
        
        print(f"Total tables: {len(results)}")
        print(f"Successful: {success_count}")
        print(f"Failed: {failed_count}")
        print(f"Total rows synced: {total_rows:,}")
        
        return results
    
    def create_warehouse_table_from_lakehouse(self, 
                                               lakehouse_table, 
                                               warehouse_schema,
                                               warehouse_table=None):
        """
        Create warehouse table with schema inferred from lakehouse table
        
        Args:
            lakehouse_table (str): Source lakehouse table
            warehouse_schema (str): Target warehouse schema
            warehouse_table (str): Target table name
            
        Returns:
            str: CREATE TABLE statement
        """
        df = self.spark.table(lakehouse_table)
        schema = df.schema
        
        target_table = warehouse_table or lakehouse_table.split('.')[-1]
        
        # Map Spark types to SQL types
        type_mapping = {
            'StringType': 'VARCHAR(MAX)',
            'IntegerType': 'INT',
            'LongType': 'BIGINT',
            'DoubleType': 'FLOAT',
            'FloatType': 'REAL',
            'BooleanType': 'BIT',
            'DateType': 'DATE',
            'TimestampType': 'DATETIME2',
            'DecimalType': 'DECIMAL(18,2)'
        }
        
        columns = []
        for field in schema.fields:
            sql_type = type_mapping.get(type(field.dataType).__name__, 'VARCHAR(MAX)')
            nullable = "NULL" if field.nullable else "NOT NULL"
            columns.append(f"    [{field.name}] {sql_type} {nullable}")
        
        create_statement = f"""
CREATE TABLE [{warehouse_schema}].[{target_table}] (
{',\n'.join(columns)}
);
"""
        
        print("Generated CREATE TABLE statement:")
        print(create_statement)
        
        return create_statement


# Example usage
if __name__ == "__main__":
    # Initialize sync utility
    sync = LakehouseWarehouseSync(warehouse_name="MyWarehouse")
    
    # Sync single table
    result = sync.sync_table(
        lakehouse_table="sales_data",
        warehouse_schema="dbo",
        mode="overwrite"
    )
    
    print(json.dumps(result, indent=2))
    
    # Bulk sync example
    # mappings = [
    #     {'source': 'sales_data', 'target_schema': 'dbo', 'mode': 'overwrite'},
    #     {'source': 'customer', 'target_schema': 'dbo', 'mode': 'append'}
    # ]
    # results = sync.bulk_sync(mappings)
