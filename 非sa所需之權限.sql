use master
GRANT VIEW ANY DEFINITION TO user_george;

1.	SHOWPLAN:�˵��C�qSQL Statement������p��
USE ODSDATA
GRANT SHOWPLAN TO user_george
USE ODSMART
GRANT SHOWPLAN TO user_george
USE ODSRPT
GRANT SHOWPLAN TO user_george
USE ODSSTAGE
GRANT SHOWPLAN TO user_george

2.	VIEW SERVER STATE:�˵��ثeSQL Server�����A
GRANT VIEW SERVER STATE TO user_george

3.	MSDB db_datareader���v��:�˵��ثeSQL Agent���Ҧ�Job
USE [msdb]
CREATE USER [user_george] FOR LOGIN [user_george]
ALTER USER [user_george] WITH DEFAULT_SCHEMA=[dbo]
EXEC sp_addrolemember N'db_datareader', N'user_george'

USE AdventureWorks 
GO 
GRANT VIEW Definition TO PUBLIC


USE [msdb]
GO
CREATE USER [Gordon] FOR LOGIN [Gordon]
GO
USE [msdb]
GO
ALTER ROLE [SQLAgentOperatorRole] ADD MEMBER [Gordon]
GO
