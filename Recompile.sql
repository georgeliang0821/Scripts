

1.	���T�{�ثeBMS Server�W�̱`�QRecompile��top 30 SP �өR�O
SELECT TOP 30
 qs.plan_generation_num,
qs.execution_count,
DB_NAME(st.dbid) AS DbName,
st.objectid,
st.TEXT
 FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
ORDER BY plan_generation_num DESC

2.�z�פWCompile���O����b�p�⪺,���ӥi��W�L1��,�i�γo�ӻy�k�p��top 30 Compile���ɶ�

-- Find high compile resource plans in the plan cache
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH XMLNAMESPACES 
(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT TOP 30
CompileTime_ms,
CompileCPU_ms,
CompileMemory_KB,
qs.execution_count,
qs.total_elapsed_time/1000 AS duration_ms,
qs.total_worker_time/1000 as cputime_ms,
(qs.total_elapsed_time/qs.execution_count)/1000 AS avg_duration_ms,
(qs.total_worker_time/qs.execution_count)/1000 AS avg_cputime_ms,
qs.max_elapsed_time/1000 AS max_duration_ms,
qs.max_worker_time/1000 AS max_cputime_ms,
SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1,
(CASE qs.statement_end_offset
WHEN -1 THEN DATALENGTH(st.text)
ELSE qs.statement_end_offset
END - qs.statement_start_offset) / 2 + 1) AS StmtText,
query_hash,
query_plan_hash
FROM
(
SELECT 
c.value('xs:hexBinary(substring((@QueryHash)[1],3))', 'varbinary(max)') AS QueryHash,
c.value('xs:hexBinary(substring((@QueryPlanHash)[1],3))', 'varbinary(max)') AS QueryPlanHash,
c.value('(QueryPlan/@CompileTime)[1]', 'int') AS CompileTime_ms,
c.value('(QueryPlan/@CompileCPU)[1]', 'int') AS CompileCPU_ms,
c.value('(QueryPlan/@CompileMemory)[1]', 'int') AS CompileMemory_KB,
qp.query_plan
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
CROSS APPLY qp.query_plan.nodes('ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS n(c)
) AS tab
JOIN sys.dm_exec_query_stats AS qs
ON tab.QueryHash = qs.query_hash
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY CompileTime_ms DESC
OPTION(RECOMPILE, MAXDOP 1)
