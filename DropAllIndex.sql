
SELECT 'DROP INDEX ['+ix.name+'] ON DBO.[' + OBJECT_NAME(ID) +'];'
 FROM sysindexes ix
 WHERE   ix.Name IS NOT null
 AND IX.NAME NOT LIKE '_WA%'
DROP INDEX [CODES-DISCOUNT_FK] ON [dbo].[BMS_PRI_DISCOUNT]
GO


