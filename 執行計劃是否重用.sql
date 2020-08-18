�z���Ѥδ��ժ���k2�i�H�����檺 T-SQL �y�k�T�w�B���פ��ܡA�B�i�H���T���ǤJ�Ѽƪ����A�Ϊ��סA�p�P SP_EXECUTESQL���ĪG�@��A�B�����ǿ骺�ƶq�]���C�D�`�h�A�o�O�D�`�n���@�k�I�]���i�H�i�@�B�T�{�@�U�A�O�_�i�H�� AD_HOC�y�k���ݭ��s�sĶ�C

��ĳ�i�H�bUAT���ҤW����Production��Execution ���ƶi�������A�i�H�[��ݬݬO�_�`����ɶ��Υ�������ɶ��O�_����֡C�u�n�@�ӻy�k�� 1ms�A�b�P�ɤj�q����y�k������CPU�ɶ��N�|�ﵽ�C

�t�~�A�p�G�n�ݰ���p�e�O�_���ݭn�sĶ�N�i�H���ΡA�i�H�ϥΥH�U���y�k��ݡC�p�G�S�w�y�k������p�e�� Execution Count ���O 1�A�N��S�����ΡA�C�����ݭn���s�sĶ�C



select 
 bucketid,
a.plan_handle,
refcounts, 
 usecounts,
execution_count,
size_in_bytes,
cacheobjtype,
objtype,
text,
query_plan,
creation_time,
last_execution_time,
execution_count,
total_elapsed_time,
last_elapsed_time
from sys.dm_exec_cached_plans a 
       inner join sys.dm_exec_query_stats b on a.plan_handle=b.plan_handle
     cross apply sys.dm_exec_sql_text(b.sql_handle) as sql_text
     cross apply sys.dm_exec_query_plan(a.plan_handle) as query_plan
where 1=1
and text like '%mybadproc%'   --���B��m�z�n�d�ߪ��y�k
-- and a.plan_handle = 0x06000B00C96DEC2AB8A16D06000000000000000000000000
and b.last_execution_time between '2014-01-20 09:00' and '2014-01-20 12:00'
order by last_execution_time desc
