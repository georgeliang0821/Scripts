--�ŧiCURSOR
DECLARE @SQL NVARCHAR(4000)
DECLARE @TableNm VARCHAR(30) --�ܼ�
DECLARE @TEMPCNT INT

SET @TEMPCNT = 0

--TblList name
DECLARE TblList CURSOR FOR 

           SELECT  'odsdba.'+REPLACE([NAME],' ','')             
           FROM pcusegdb_pd.dbo.sysobjects
           WHERE NAME LIKE 'FS_%'; -- cursor�̪����
   
        OPEN TblList; -- �}�l����
        FETCH NEXT FROM TblList --�Ĥ@��
             INTO @TableNm -- cursor�̪��ܼ�    
                                                                                                          
        WHILE @@FETCH_STATUS = 0   --�����ɴN����
     
BEGIN --�}�l�i��@�~
   
   IF @TEMPCNT <> 0 BEGIN
   set @SQL=@SQl + N' UNION ALL SELECT DISTINCT CONVERT(CHAR(8),DATADT,112),'''+REPLACE(@TableNm,' ','')+''' FROM '+ @TableNm+' WHERE DATADT NOT IN (''20051201'',''20060101'')'
   END ELSE BEGIN 
   SET @SQL=N'SELECT DISTINCT convert(char(8),DATADT,112) ,'''+@TableNm+''' FROM '+ @TableNm+' WHERE DATADT NOT IN (''20051201'',''20060101'')'
   END 

       
   FETCH NEXT FROM TblList --�i��U�@��
   INTO @TableNm    
              SET @TEMPCNT = @TEMPCNT +1;
END   

CLOSE TblList;        --����cursor                                                                                                              
DEALLOCATE TblList;

--PRINT @SQL
 EXEC SP_EXECUTESQL @SQL


