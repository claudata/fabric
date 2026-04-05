-- =============================================
-- Fabric Data Warehouse - Data Quality Checks
-- =============================================
-- Comprehensive data quality validation queries
-- Author: Claudio Da Silva
-- =============================================

-- =============================================
-- 1. NULL Value Analysis
-- Check null percentages in all columns
-- =============================================
-- Note: Replace 'YourSchema' and 'YourTable' with actual values

DECLARE @SchemaName NVARCHAR(128) = 'dbo';
DECLARE @TableName NVARCHAR(128) = 'YourTable';
DECLARE @SQL NVARCHAR(MAX) = '';

-- Generate dynamic SQL to check nulls in all columns
SELECT @SQL = @SQL + 
    'SELECT ''' + COLUMN_NAME + ''' AS column_name, ' +
    'COUNT(*) AS total_rows, ' +
    'SUM(CASE WHEN [' + COLUMN_NAME + '] IS NULL THEN 1 ELSE 0 END) AS null_count, ' +
    'CAST(100.0 * SUM(CASE WHEN [' + COLUMN_NAME + '] IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS null_percentage ' +
    'FROM [' + @SchemaName + '].[' + @TableName + '] UNION ALL '
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_SCHEMA = @SchemaName 
    AND TABLE_NAME = @TableName;

-- Remove trailing UNION ALL
SET @SQL = LEFT(@SQL, LEN(@SQL) - 10);
SET @SQL = @SQL + ' ORDER BY null_percentage DESC';

PRINT @SQL; -- Print for review
-- EXEC sp_executesql @SQL; -- Execute to see results

-- =============================================
-- 2. Duplicate Record Detection
-- Generic template for finding duplicates
-- =============================================
-- Replace with your actual key columns

SELECT 
    -- Add your key columns here
    col1,
    col2,
    col3,
    COUNT(*) AS duplicate_count
FROM 
    [schema_name].[table_name]
GROUP BY 
    col1, col2, col3
HAVING 
    COUNT(*) > 1
ORDER BY 
    duplicate_count DESC;

-- =============================================
-- 3. Referential Integrity Check
-- Check for orphaned records (child records without parent)
-- =============================================
-- Example: Orders without valid customers

SELECT 
    o.order_id,
    o.customer_id,
    'Orphaned: Customer does not exist' AS issue
FROM 
    dbo.orders o
LEFT JOIN 
    dbo.customers c ON o.customer_id = c.customer_id
WHERE 
    c.customer_id IS NULL;

-- =============================================
-- 4. Data Range Validation
-- Check for values outside expected ranges
-- =============================================

-- Example: Invalid dates
SELECT 
    COUNT(*) AS invalid_date_count
FROM 
    dbo.orders
WHERE 
    order_date < '1900-01-01' 
    OR order_date > GETDATE() + 1; -- Future dates

-- Example: Invalid numeric ranges
SELECT 
    COUNT(*) AS invalid_quantity_count
FROM 
    dbo.order_details
WHERE 
    quantity <= 0 
    OR quantity > 10000; -- Suspiciously high

-- Example: Invalid amounts
SELECT 
    COUNT(*) AS negative_amount_count
FROM 
    dbo.invoices
WHERE 
    total_amount < 0;

-- =============================================
-- 5. String Data Quality Checks
-- =============================================

-- Check for empty strings vs NULL
SELECT 
    'empty_strings' AS check_type,
    COUNT(*) AS count
FROM 
    dbo.customers
WHERE 
    email = ''
UNION ALL
SELECT 
    'null_emails' AS check_type,
    COUNT(*) AS count
FROM 
    dbo.customers
WHERE 
    email IS NULL;

-- Check for leading/trailing spaces
SELECT 
    customer_id,
    customer_name,
    LEN(customer_name) AS length_with_spaces,
    LEN(LTRIM(RTRIM(customer_name))) AS length_trimmed
FROM 
    dbo.customers
WHERE 
    LEN(customer_name) <> LEN(LTRIM(RTRIM(customer_name)));

-- Check for invalid email formats
SELECT 
    customer_id,
    email
FROM 
    dbo.customers
WHERE 
    email NOT LIKE '%@%.%'
    AND email IS NOT NULL
    AND email <> '';

-- =============================================
-- 6. Completeness Check - Required Fields
-- Ensure critical fields are populated
-- =============================================

SELECT 
    'Missing Customer Name' AS issue,
    COUNT(*) AS count
FROM 
    dbo.customers
WHERE 
    customer_name IS NULL OR customer_name = ''
UNION ALL
SELECT 
    'Missing Email' AS issue,
    COUNT(*) AS count
FROM 
    dbo.customers
WHERE 
    email IS NULL OR email = ''
UNION ALL
SELECT 
    'Missing Phone' AS issue,
    COUNT(*) AS count
FROM 
    dbo.customers
WHERE 
    phone IS NULL OR phone = '';

-- =============================================
-- 7. Consistency Checks
-- Cross-field validation
-- =============================================

-- Example: Start date should be before end date
SELECT 
    project_id,
    start_date,
    end_date
FROM 
    dbo.projects
WHERE 
    end_date < start_date;

-- Example: Discount should not exceed total amount
SELECT 
    order_id,
    total_amount,
    discount_amount
FROM 
    dbo.orders
WHERE 
    discount_amount > total_amount;

-- =============================================
-- 8. Uniqueness Validation
-- Check unique constraints at application level
-- =============================================

-- Find duplicate emails (should be unique)
SELECT 
    email,
    COUNT(*) AS duplicate_count
FROM 
    dbo.customers
WHERE 
    email IS NOT NULL
GROUP BY 
    email
HAVING 
    COUNT(*) > 1;

-- Find duplicate order numbers
SELECT 
    order_number,
    COUNT(*) AS duplicate_count
FROM 
    dbo.orders
GROUP BY 
    order_number
HAVING 
    COUNT(*) > 1;

-- =============================================
-- 9. Data Freshness Check
-- Identify stale data
-- =============================================

-- Records not updated in X days
DECLARE @StaleThresholdDays INT = 90;

SELECT 
    TABLE_SCHEMA AS schema_name,
    TABLE_NAME AS table_name,
    'Check manually for last_updated column' AS note
FROM 
    INFORMATION_SCHEMA.TABLES
WHERE 
    TABLE_TYPE = 'BASE TABLE'
    AND TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA');

-- Example with actual date column
/*
SELECT 
    COUNT(*) AS stale_record_count,
    MAX(last_updated) AS most_recent_update,
    DATEDIFF(DAY, MAX(last_updated), GETDATE()) AS days_since_update
FROM 
    dbo.product_catalog
WHERE 
    last_updated < DATEADD(DAY, -@StaleThresholdDays, GETDATE());
*/

-- =============================================
-- 10. Comprehensive Data Quality Report
-- Combines multiple checks
-- =============================================

CREATE OR ALTER PROCEDURE dbo.sp_DataQualityReport
    @SchemaName NVARCHAR(128),
    @TableName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TotalRows BIGINT;

    -- Get total row count
    SET @SQL = 'SELECT @TotalRows = COUNT(*) FROM [' + @SchemaName + '].[' + @TableName + ']';
    EXEC sp_executesql @SQL, N'@TotalRows BIGINT OUTPUT', @TotalRows OUTPUT;

    -- Summary report
    SELECT 
        @SchemaName AS schema_name,
        @TableName AS table_name,
        @TotalRows AS total_rows,
        GETDATE() AS report_timestamp;

    -- Column-level quality metrics would go here
    SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        IS_NULLABLE,
        CHARACTER_MAXIMUM_LENGTH
    FROM 
        INFORMATION_SCHEMA.COLUMNS
    WHERE 
        TABLE_SCHEMA = @SchemaName 
        AND TABLE_NAME = @TableName
    ORDER BY 
        ORDINAL_POSITION;
END;
GO

-- Execute the report
-- EXEC dbo.sp_DataQualityReport @SchemaName = 'dbo', @TableName = 'YourTable';

-- =============================================
-- Usage Notes:
-- - Customize for your specific tables and business rules
-- - Schedule regular execution for monitoring
-- - Set up alerts for critical quality violations
-- - Document expected ranges and formats
-- =============================================
