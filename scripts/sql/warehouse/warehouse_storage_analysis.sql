-- =============================================
-- Fabric Data Warehouse - Storage and Table Analysis
-- =============================================
-- Analyze storage consumption, table sizes, and growth patterns
-- Author: Claudio Da Silva
-- =============================================

-- 1. Database Size Overview
SELECT 
    DB_NAME() AS database_name,
    'Data Warehouse' AS warehouse_type,
    GETDATE() AS analysis_timestamp;

-- =============================================
-- 2. Table Row Counts and Sizes
-- Lists all user tables with row counts
-- =============================================
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    i.rows AS row_count,
    i.type_desc AS index_type,
    FORMAT(i.rows, 'N0') AS formatted_row_count
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
WHERE 
    i.index_id IN (0, 1)  -- Heap or clustered index
    AND s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY 
    i.rows DESC;

-- =============================================
-- 3. Table Storage Details
-- Shows storage allocation per table
-- =============================================
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    p.rows AS row_count,
    SUM(a.total_pages) AS total_pages,
    SUM(a.used_pages) AS used_pages,
    SUM(a.data_pages) AS data_pages,
    (SUM(a.total_pages) * 8) / 1024.0 AS total_space_mb,
    (SUM(a.used_pages) * 8) / 1024.0 AS used_space_mb,
    (SUM(a.data_pages) * 8) / 1024.0 AS data_space_mb
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
    s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
GROUP BY 
    s.name, t.name, p.rows
ORDER BY 
    total_space_mb DESC;

-- =============================================
-- 4. Schema-Level Storage Summary
-- Aggregated storage by schema
-- =============================================
SELECT 
    s.name AS schema_name,
    COUNT(DISTINCT t.name) AS table_count,
    SUM(p.rows) AS total_rows,
    FORMAT(SUM(p.rows), 'N0') AS formatted_row_count,
    SUM(a.total_pages) * 8 / 1024.0 AS total_space_mb,
    SUM(a.used_pages) * 8 / 1024.0 AS used_space_mb,
    ROUND(SUM(a.total_pages) * 8 / 1024.0 / 1024.0, 2) AS total_space_gb
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
    s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
GROUP BY 
    s.name
ORDER BY 
    total_space_mb DESC;

-- =============================================
-- 5. Empty or Small Tables
-- Identify tables that may not be needed
-- =============================================
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    p.rows AS row_count,
    t.create_date,
    t.modify_date
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
WHERE 
    i.index_id IN (0, 1)
    AND p.rows < 1000  -- Tables with less than 1000 rows
    AND s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY 
    p.rows, s.name, t.name;

-- =============================================
-- 6. Largest Tables - Top 20
-- Quick view of space consumers
-- =============================================
SELECT TOP 20
    s.name + '.' + t.name AS full_table_name,
    p.rows AS row_count,
    FORMAT(p.rows, 'N0') AS formatted_rows,
    ROUND((SUM(a.total_pages) * 8) / 1024.0, 2) AS size_mb,
    ROUND((SUM(a.total_pages) * 8) / 1024.0 / 1024.0, 2) AS size_gb
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
    s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
GROUP BY 
    s.name, t.name, p.rows
ORDER BY 
    size_mb DESC;

-- =============================================
-- 7. Column Statistics
-- Useful for understanding data distribution
-- =============================================
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    st.name AS stats_name,
    STATS_DATE(st.object_id, st.stats_id) AS last_updated,
    DATEDIFF(DAY, STATS_DATE(st.object_id, st.stats_id), GETDATE()) AS days_old
FROM 
    sys.stats st
INNER JOIN 
    sys.tables t ON st.object_id = t.object_id
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.stats_columns sc ON st.object_id = sc.object_id AND st.stats_id = sc.stats_id
INNER JOIN 
    sys.columns c ON sc.object_id = c.object_id AND sc.column_id = c.column_id
WHERE 
    s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY 
    days_old DESC, s.name, t.name;

-- =============================================
-- 8. Table Metadata Summary
-- Complete table catalog
-- =============================================
SELECT 
    TABLE_SCHEMA AS schema_name,
    TABLE_NAME AS table_name,
    TABLE_TYPE AS table_type,
    (
        SELECT COUNT(*) 
        FROM INFORMATION_SCHEMA.COLUMNS c 
        WHERE c.TABLE_SCHEMA = t.TABLE_SCHEMA 
        AND c.TABLE_NAME = t.TABLE_NAME
    ) AS column_count
FROM 
    INFORMATION_SCHEMA.TABLES t
WHERE 
    TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY 
    TABLE_SCHEMA, TABLE_NAME;

-- =============================================
-- 9. Data Type Usage Summary
-- Shows most common data types across all tables
-- =============================================
SELECT 
    DATA_TYPE,
    COUNT(*) AS column_count,
    COUNT(DISTINCT TABLE_SCHEMA + '.' + TABLE_NAME) AS table_count
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA')
GROUP BY 
    DATA_TYPE
ORDER BY 
    column_count DESC;

-- =============================================
-- Usage Notes:
-- - Run regularly to monitor storage growth
-- - Use for capacity planning
-- - Identify candidates for archival or cleanup
-- - Monitor statistics freshness for query optimization
-- =============================================
