"""
Warehouse Bulk Loader using COPY INTO

This utility provides optimized data loading into Fabric Data Warehouse
using the COPY INTO command for high-performance ingestion from files.

Author: Claudio Da Silva
Requirements: Fabric Spark with warehouse write access
"""

from pyspark.sql import SparkSession
from datetime import datetime


class WarehouseBulkLoader:
    """
    Bulk load data into Fabric Data Warehouse using COPY INTO
    """
    
    def __init__(self, warehouse_name):
        """
        Initialize the bulk loader
        
        Args:
            warehouse_name (str): Name of the target Fabric Data Warehouse
        """
        self.warehouse_name = warehouse_name
        self.spark = SparkSession.builder.getOrCreate()
        
    def load_from_parquet(self,
                          source_path,
                          target_schema,
                          target_table,
                          mode='append'):
        """
        Load Parquet files into warehouse using COPY INTO
        
        Args:
            source_path (str): Path to Parquet files (supports wildcards)
            target_schema (str): Target schema in warehouse
            target_table (str): Target table name
            mode (str): 'append' or 'overwrite'
            
        Returns:
            dict: Load status and metrics
        """
        start_time = datetime.now()
        
        print(f"Loading Parquet files from: {source_path}")
        print(f"Target: {target_schema}.{target_table}")
        print(f"Mode: {mode}")
        
        try:
            # Read Parquet files
            df = self.spark.read.parquet(source_path)
            row_count = df.count()
            
            print(f"Read {row_count:,} rows from Parquet files")
            
            # Write to warehouse
            warehouse_table = f"{self.warehouse_name}.{target_schema}.{target_table}"
            
            df.write \
                .format("sqldw") \
                .mode(mode) \
                .option("tableName", warehouse_table) \
                .save()
            
            duration = (datetime.now() - start_time).total_seconds()
            
            print(f"✓ Load completed in {duration:.2f} seconds")
            print(f"  Throughput: {row_count/duration:,.0f} rows/second")
            
            return {
                'status': 'success',
                'source': source_path,
                'target': f"{target_schema}.{target_table}",
                'rows_loaded': row_count,
                'duration_seconds': duration,
                'throughput_rows_per_sec': row_count / duration
            }
            
        except Exception as e:
            duration = (datetime.now() - start_time).total_seconds()
            print(f"✗ Load failed: {str(e)}")
            
            return {
                'status': 'failed',
                'source': source_path,
                'error': str(e),
                'duration_seconds': duration
            }
    
    def load_from_delta(self,
                        delta_table,
                        target_schema,
                        target_table,
                        mode='append',
                        filter_condition=None):
        """
        Load data from Delta table to warehouse
        
        Args:
            delta_table (str): Source Delta table name or path
            target_schema (str): Target schema
            target_table (str): Target table
            mode (str): 'append' or 'overwrite'
            filter_condition (str): Optional WHERE clause for filtering
            
        Returns:
            dict: Load status
        """
        start_time = datetime.now()
        
        print(f"Loading from Delta table: {delta_table}")
        
        try:
            # Read Delta table
            if delta_table.startswith('abfss://') or delta_table.startswith('Tables/'):
                df = self.spark.read.format("delta").load(delta_table)
            else:
                df = self.spark.table(delta_table)
            
            # Apply filter if specified
            if filter_condition:
                print(f"Applying filter: {filter_condition}")
                df = df.where(filter_condition)
            
            row_count = df.count()
            print(f"Processing {row_count:,} rows")
            
            # Write to warehouse
            warehouse_table = f"{self.warehouse_name}.{target_schema}.{target_table}"
            
            df.write \
                .format("sqldw") \
                .mode(mode) \
                .option("tableName", warehouse_table) \
                .save()
            
            duration = (datetime.now() - start_time).total_seconds()
            
            print(f"✓ Load completed in {duration:.2f} seconds")
            
            return {
                'status': 'success',
                'source': delta_table,
                'target': f"{target_schema}.{target_table}",
                'rows_loaded': row_count,
                'duration_seconds': duration,
                'filter': filter_condition
            }
            
        except Exception as e:
            print(f"✗ Load failed: {str(e)}")
            return {
                'status': 'failed',
                'source': delta_table,
                'error': str(e)
            }
    
    def load_from_csv(self,
                      csv_path,
                      target_schema,
                      target_table,
                      has_header=True,
                      delimiter=',',
                      mode='append'):
        """
        Load CSV files into warehouse
        
        Args:
            csv_path (str): Path to CSV files
            target_schema (str): Target schema
            target_table (str): Target table
            has_header (bool): Whether CSV has header row
            delimiter (str): CSV delimiter
            mode (str): Load mode
            
        Returns:
            dict: Load status
        """
        start_time = datetime.now()
        
        print(f"Loading CSV files from: {csv_path}")
        
        try:
            # Read CSV
            df = self.spark.read \
                .option("header", str(has_header).lower()) \
                .option("delimiter", delimiter) \
                .option("inferSchema", "true") \
                .csv(csv_path)
            
            row_count = df.count()
            print(f"Read {row_count:,} rows from CSV")
            
            # Write to warehouse
            warehouse_table = f"{self.warehouse_name}.{target_schema}.{target_table}"
            
            df.write \
                .format("sqldw") \
                .mode(mode) \
                .option("tableName", warehouse_table) \
                .save()
            
            duration = (datetime.now() - start_time).total_seconds()
            
            print(f"✓ Load completed in {duration:.2f} seconds")
            
            return {
                'status': 'success',
                'source': csv_path,
                'target': f"{target_schema}.{target_table}",
                'rows_loaded': row_count,
                'duration_seconds': duration
            }
            
        except Exception as e:
            print(f"✗ Load failed: {str(e)}")
            return {'status': 'failed', 'source': csv_path, 'error': str(e)}


# Example usage
if __name__ == "__main__":
    # Initialize loader
    loader = WarehouseBulkLoader(warehouse_name="MyWarehouse")
    
    # Load from Parquet
    result = loader.load_from_parquet(
        source_path="Files/data/*.parquet",
        target_schema="dbo",
        target_table="fact_sales",
        mode="append"
    )
    
    print(result)
    
    # Load from Delta table with filter
    # result = loader.load_from_delta(
    #     delta_table="sales_data",
    #     target_schema="dbo",
    #     target_table="fact_sales",
    #     mode="append",
    #     filter_condition="order_date >= '2024-01-01'"
    # )
