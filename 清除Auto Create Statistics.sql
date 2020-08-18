(1)	I provide some T-SQL utilities for troubleshooting performance issue:

1)	�H�U�w���Ʈw Auto Create Statistics (_WA_SYS)����ĳ(�L�Ϊ� Statistics �i��v�T���ͥ��T������p�e)�G

1.	�z�i�H���N��Ʈw�{���� Auto Create Statistics �i��M�z�ʧ@�ASQL Server �|�̾ڻy�k������A�۰ʫإ�

/*
�@���M���Ҧ���ƪ�W�ASQL Server �۰ʫإߪ��έp��T (�H_WA_Sys �R�W���έp��T)
*/

DECLARE @ObjectName sysname
DECLARE @StatsName sysname
DECLARE @SchemaName sysname

DECLARE StatsCursor CURSOR FAST_FORWARD
FOR
	SELECT (tblSchema.TABLE_SCHEMA + '.' + tbl.name) AS ObjectName, st.name AS StatsName
	FROM sys.tables AS tbl 
	INNER JOIN sys.stats st ON st.object_id=tbl.object_id
	INNER JOIN information_schema.tables tblSchema
	ON tbl.name = tblSchema.TABLE_NAME
	WHERE st.auto_created  = 1

OPEN StatsCursor
FETCH NEXT FROM StatsCursor
	INTO @ObjectName, @StatsName
	WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT 'DROP STATISTICS ' + @ObjectName + '.' + @StatsName
			EXEC ('DROP STATISTICS ' + @ObjectName + '.' + @StatsName)
			FETCH NEXT FROM StatsCursor
			INTO @ObjectName, @StatsName
		END
CLOSE StatsCursor
DEALLOCATE StatsCursor


2.	�p�G�٦� Auto Create Statistics (_WA_SYS) ���͡A���˵��� Statistics �q���@����첣�͡A���U�ӷj�M�Ҧ��� T-SQL �y�k�A�˵��O�_���ϥΨ�����@���d�߱���A�p�G�����ܽе�����ϥ��W�v�A�O�_�ݭn�N�����W�[�@�� Index�C�p�G�z�M�w�n�W�[����쪺 Index�A�Цb�W�[������A�N������Auto Create Statistics (_WA_SYS)�M���C

�аѦҡG
SQL Server Statistics: Problems and Solutions
http://www.simple-talk.com/sql/performance/sql-server-statistics-problems-and-solutions/  

Why does Update Stats with SAMPLE take longer then FULLSCAN?
http://www.sql-server-performance.com/forum/threads/why-does-update-stats-with-sample-take-longer-then-fullscan.29194/ 

Execution Plan Basics
http://www.simple-talk.com/sql/performance/execution-plan-basics/ 

Update SQL Server table statistics for performance kick
http://searchsqlserver.techtarget.com/tip/Update-SQL-Server-table-statistics-for-performance-kick 

--Use DBCC UpdateStstistics with FULLSCAN on every Table on Specific Database

Set nocount on

-- <<<< Please change the following Database name >>>>
USE {Database_Name}
---------------

declare @db_name as sysname
set @db_name = DB_NAME()

--For SQL Server 2000
declare tables cursor for
select quotename(User_Name(uid))+'.'+ quotename(Object_Name(id)) as [Schema Table] 
from sysObjects 
where xtype = 'U'
And (quotename(User_Name(uid))+'.'+ quotename(Object_Name(id)))is not null
order by name

Open tables 

declare @table_name as sysname
declare @reserved_size as VarChar(10)
declare @int_reserved_size as int
DECLARE @ExecuteString NVARCHAR(500)

--Initial Variables
Set @ExecuteString = ''

--Start Cursor 
Fetch next from tables into @table_name
while (@@fetch_status=0) 
  Begin
  
            print '========== Information ==================='
            print 'Table [' + @table_name + '] Is Processed!'   
            print '=========================================='
  
                Set @ExecuteString = 'UPDATE STATISTICS ' + @table_name + ' WITH FULLSCAN'
                Print 'Executing UPDATE STATISTICS  : ' + @ExecuteString              
                EXEC SP_ExecuteSql @ExecuteString         
      
      Set @ExecuteString = ''
      Fetch next from tables into @table_name

  End 
 
Close tables
Deallocate tables

2)	��ʰ���C�@�� Table Re-index ���y�k(��֯��� Fragment �Τ@�֧�s�έp��T )�G

set nocount on

--�Эק��Ʈw�W��
use Adventureworks

declare @db_name as char(50)
select @db_name = name from sys.sysdatabases where dbid=DB_ID()

declare tables cursor for
select name from sysobjects where xtype = 'U' order by name

open tables 
 
declare @name as sysname
declare @reserved_size as VarChar(10)
declare @int_reserved_size as int

--Start Cursor 
fetch next from tables into @name

    while (@@fetch_status=0)
     
      begin
      
       Begin
     
          print '========== Information ================'
          PRINT 'Table <' + @name + '> Is Processed!' 
          print '=================================='
     
          DBCC DBREINDEX(@name,'',70)
     
          End 
     
  fetch next from tables into @name

  end 
 
close tables
deallocate tables
