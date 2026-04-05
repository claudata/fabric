-- =============================================
-- Fabric Data Warehouse - Query Performance Analysis
-- =============================================
-- This script helps identify and analyze query performance issues
-- Author: Claudio Da Silva
-- =============================================

-- 1. Currently Running Queries
-- Shows all active queries with execution time
SELECT 
    r.session_id,
    r.request_id,
    r.start_time,
    DATEDIFF(SECOND, r.start_time, GETDATE()) AS elapsed_seconds,
    r.status,
    r.command,
    r.total_elapsed_time / 1000 AS total_elapsed_seconds,
    r.cpu_time / 1000 AS cpu_seconds,
    t.text AS query_text,
    r.blocking_session_id,
    r.wait_type,
    r.wait_time / 1000 AS wait_seconds
FROM 
    sys.dm_exec_requests r
CROSS APPLY 
    sys.dm_exec_sql_text(r.sql_handle) t
WHERE 
    r.session_id <> @@SPID  -- Exclude current session
    AND r.session_id > 50   -- Exclude system sessions
ORDER BY 
    r.start_time;

-- =============================================
-- 2. Query Execution History (Last 24 hours)
-- Note: Requires query store to be enabled
-- =============================================

-- Check if Query Store is enabled
SELECT 
    name AS database_name,
    is_query_store_on
FROM 
    sys.databases
WHERE 
    database_id = DB_ID();

-- If Query Store is enabled, show top queries by execution time
-- (Uncomment if Query Store is available in Fabric DW)
/*
SELECT TOP 20
    q.query_id,
    qt.query_sql_text,
    rs.count_executions AS execution_count,
    rs.avg_duration / 1000000.0 AS avg_duration_seconds,
    rs.max_duration / 1000000.0 AS max_duration_seconds,
    rs.avg_cpu_time / 1000000.0 AS avg_cpu_seconds,
    rs.avg_logical_io_reads,
    rs.last_execution_time
FROM 
    sys.query_store_query q
INNER JOIN 
    sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
INNER JOIN 
    sys.query_store_plan p ON q.query_id = p.query_id
INNER JOIN 
    sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE 
    rs.last_execution_time >= DATEADD(hour, -24, GETUTCDATE())
ORDER BY 
    rs.avg_duration DESC;
*/

-- =============================================
-- 3. Sessions and Connections
-- =============================================
SELECT 
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status,
    s.cpu_time,
    s.memory_usage,
    s.total_scheduled_time,
    s.last_request_start_time,
    s.last_request_end_time,
    c.connect_time,
    c.net_transport,
    c.client_net_address
FROM 
    sys.dm_exec_sessions s
LEFT JOIN 
    sys.dm_exec_connections c ON s.session_id = c.session_id
WHERE 
    s.session_id > 50  -- Exclude system sessions
ORDER BY 
    s.last_request_start_time DESC;

-- =============================================
-- 4. Blocking Sessions
-- Identify queries blocking other queries
-- =============================================
SELECT 
    blocking.session_id AS blocking_session,
    blocked.session_id AS blocked_session,
    blocking_text.text AS blocking_query,
    blocked_text.text AS blocked_query,
    DATEDIFF(SECOND, blocked.start_time, GETDATE()) AS blocked_duration_seconds,
    blocked.wait_type,
    blocked.wait_time / 1000 AS wait_seconds
FROM 
    sys.dm_exec_requests blocked
INNER JOIN 
    sys.dm_exec_requests blocking ON blocked.blocking_session_id = blocking.session_id
CROSS APPLY 
    sys.dm_exec_sql_text(blocking.sql_handle) blocking_text
CROSS APPLY 
    sys.dm_exec_sql_text(blocked.sql_handle) blocked_text
WHERE 
    blocked.blocking_session_id > 0;

-- =============================================
-- 5. Wait Statistics
-- Shows what queries are waiting for
-- =============================================
SELECT TOP 20
    wait_type,
    waiting_tasks_count,
    wait_time_ms / 1000.0 AS wait_time_seconds,
    wait_time_ms / 1000.0 / NULLIF(waiting_tasks_count, 0) AS avg_wait_seconds,
    percentage = ROUND(100.0 * wait_time_ms / SUM(wait_time_ms) OVER(), 2)
FROM 
    sys.dm_os_wait_stats
WHERE 
    wait_type NOT IN (
        'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
        'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 
        'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH',
        'XE_TIMER_EVENT', 'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 
        'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT', 'DISPATCHER_QUEUE_SEMAPHORE',
        'FT_IFTS_SCHEDULER_IDLE_WAIT', 'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN'
    )
    AND wait_time_ms > 0
ORDER BY 
    wait_time_ms DESC;

-- =============================================
-- 6. Result Set Cache Statistics (Fabric DW Feature)
-- Shows cache hit rates for query performance optimization
-- =============================================
-- Note: Result set caching is automatic in Fabric DW
-- Monitor using execution plans and query duration patterns

-- =============================================
-- 7. Long Running Query Detection Template
-- Create an alert/monitoring query
-- =============================================
DECLARE @LongRunningThresholdSeconds INT = 300; -- 5 minutes

SELECT 
    'ALERT: Long Running Query' AS alert_type,
    r.session_id,
    r.start_time,
    DATEDIFF(SECOND, r.start_time, GETDATE()) AS elapsed_seconds,
    r.status,
    r.command,
    t.text AS query_text,
    r.cpu_time / 1000 AS cpu_seconds,
    r.wait_type
FROM 
    sys.dm_exec_requests r
CROSS APPLY 
    sys.dm_exec_sql_text(r.sql_handle) t
WHERE 
    DATEDIFF(SECOND, r.start_time, GETDATE()) > @LongRunningThresholdSeconds
    AND r.session_id > 50
ORDER BY 
    elapsed_seconds DESC;

-- =============================================
-- Usage Notes:
-- - Run these queries in the Fabric DW SQL endpoint
-- - Schedule regular monitoring using the long-running query template
-- - Use for troubleshooting performance issues
-- - Fabric DW auto-optimizes many aspects, focus on query patterns
-- =============================================
