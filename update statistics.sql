1. �T�{odsdb_2010�O�_���}��auto update statistics
sp_dboption @dbname =  'odsdb_2010' ,  @optname =  'auto update statistics'
sp_dboption @dbname =  'odsdb_2010' ,  @optname =  'auto create statistics'
 
2.��sNLMR��STATISTICS
USE ODSDB_2010
GO
DBCC UPDATEUSAGE ('ODSDB_2010','odsdba.ODSMS_UN_NLMR');
 
USE ODSDB_2010
GO
sp_spaceused ('odsdba.ODSMS_UN_NLMR, @updateusage =  'true')
exec sp_spaceused @objname ='dbo.BL_INV_DTL_REV', @updateusage = 'true'


DBCC SHOW_STATISTICS (table_name,index_name)