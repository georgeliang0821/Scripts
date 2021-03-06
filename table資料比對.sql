USE [ODSDB]
GO
/****** 物件:  StoredProcedure [odsdba].[SP_CHK_SSIS_UPGRAGE]    指令碼日期: 06/12/2007 12:56:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [odsdba].[SP_CHK_SSIS_UPGRAGE]
@TABLE_NAME VARCHAR(255)
AS
/*確認輸入參數是否存在於實體資料庫*/
IF NOT EXISTS(SELECT * FROM ODSDB.dbo.SYSOBJECTS WHERE [NAME]=@TABLE_NAME)
  BEGIN
    GOTO NAME_ERROR_STEP
  END
/* 抓取表格資訊 */
SELECT  /*SEQ NUMBER*/  IDENTITY(INT,1,1) AS ROWNUM
       ,/*TABLE NAME*/  A.NAME AS TB 
       ,/*FIELD NAME*/  B.NAME AS FD
       ,/*DATA TYPE */  C.NAME AS DATATYPE
INTO #TB_SCHEMA 
FROM ODSDB.dbo.SYSOBJECTS A
JOIN ODSDB.dbo.SYSCOLUMNS B ON A.ID=B.ID
JOIN ODSDB.dbo.SYSTYPES C ON B.XTYPE=C.XTYPE
WHERE A.NAME=REPLACE(@TABLE_NAME,'odsdba.','') AND A.XTYPE='U'
ORDER BY B.COLID

/* 抓取主鍵資訊 */
SELECT /*SEQ NUMBER*/  IDENTITY(INT,1,1) AS ROWNUM
      ,/*TABLE NAME */  A.[NAME] AS TB
      ,/*INDEX NAME */  C.[NAME] AS IX_NAME
      ,/*COLUMN NAME*/  E.[NAME]   AS FD
INTO #PK_SCHEMA
FROM ODSDB.dbo.SYSOBJECTS A
JOIN ODSDB.dbo.SYSINDEXES C ON A.ID=C.ID
JOIN ODSDB.dbo.SYSINDEXKEYS D ON C.ID=D.ID AND C.INDID=D.INDID
JOIN ODSDB.dbo.SYSCOLUMNS E ON E.ID=C.ID AND D.COLID=E.COLID
WHERE A.NAME=REPLACE(@TABLE_NAME,'odsdba.','')
ORDER BY A.[NAME],C.INDID,D.KEYNO



DECLARE @PK_COUNT INT 
DECLARE @QT_ST INT
DECLARE @QT_END INT
DECLARE @FD VARCHAR(1000)
DECLARE @SQL_SEL VARCHAR(MAX)
DECLARE @SQL_WHR VARCHAR(MAX)
DECLARE @SQL_FRM VARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @DATATYPE VARCHAR(20)
DECLARE @NULLVALUE VARCHAR(10)
SELECT @PK_COUNT=COUNT(*) FROM #PK_SCHEMA  --筆數為0，則代表表格無主鍵

SET @SQL_SEL='SELECT COUNT(*) '
SET @SQL_WHR=' WHERE '

SET @QT_ST=1
SELECT @QT_END=COUNT(*) FROM #TB_SCHEMA
IF @PK_COUNT>0
  BEGIN   --TABLE有建PK
	SET @SQL_FRM='FROM ODSDB.odsdba.'+@TABLE_NAME+' A JOIN TESTDB.odsdba.'+@TABLE_NAME+' B ON '
    WHILE @QT_ST<=@PK_COUNT --PK個數
      BEGIN
        SELECT @FD=FD FROM #PK_SCHEMA WHERE ROWNUM=@QT_ST  
        SET @SQL_FRM=@SQL_FRM+'A.['+@FD+']='+'B.['+@FD+'] AND '
        SET @QT_ST=@QT_ST+1
      END
    SET @SQL_FRM=SUBSTRING(@SQL_FRM,1,LEN(@SQL_FRM)-4) --去除多餘AND
    SET @QT_ST=1
    WHILE @QT_ST<=@QT_END
      BEGIN
        SELECT @FD=FD,@DATATYPE=DATATYPE FROM #TB_SCHEMA WHERE ROWNUM=@QT_ST 
        SELECT @NULLVALUE=(SELECT CASE WHEN @DATATYPE IN ('INT','DECIMAL','NUMERIC','bigint','smallint','tinyint') THEN '0'
                                       WHEN @DATATYPE LIKE '%CHAR%' THEN '''*****'''
                                       WHEN @DATATYPE LIKE '%TIME%' THEN '''19000103''' ELSE '0' END)
        SET @SQL_WHR=@SQL_WHR+'ISNULL(A.['+@FD+'],'+@NULLVALUE+')=ISNULL(B.['+@FD+'],'+@NULLVALUE+') '+CHAR(13)+CHAR(10)+' AND '
        SET @QT_ST=@QT_ST+1
      END
    SELECT @SQL_WHR=SUBSTRING(@SQL_WHR,1,LEN(@SQL_WHR)-4)  --去除多餘AND
  END
  ELSE
  BEGIN  --TABLE沒建PK
    SET @SQL_FRM='FROM (SELECT DISTINCT * FROM ODSDB.odsdba.'+@TABLE_NAME+') A JOIN (SELECT DISTINCT * FROM TESTDB.odsdba.'+@TABLE_NAME+') B ON '
    WHILE @QT_ST<=@QT_END
      BEGIN
        SELECT @FD=FD,@DATATYPE=DATATYPE FROM #TB_SCHEMA WHERE ROWNUM=@QT_ST  
        SELECT @NULLVALUE=(SELECT CASE WHEN @DATATYPE IN ('INT','DECIMAL','NUMERIC','bigint','smallint','tinyint') THEN '0'
                                       WHEN @DATATYPE LIKE '%CHAR%' THEN '''*****'''
                                       WHEN @DATATYPE LIKE '%TIME%' THEN '''19000103''' ELSE '0' END)
        SET @SQL_FRM=@SQL_FRM+'ISNULL(A.['+@FD+'],'+@NULLVALUE+')='+'ISNULL(B.['+@FD+'],'+@NULLVALUE+')'+CHAR(13)+CHAR(10)+' AND '        
        SET @QT_ST=@QT_ST+1        
      END
    SELECT @SQL_FRM=SUBSTRING(@SQL_FRM,1,LEN(@SQL_FRM)-4)
    SET @SQL_WHR=''
  END

/*計算筆數*/
DECLARE @ROW_JOIN INT
DECLARE @ROW_ODS INT
DECLARE @ROW_TEST INT
DECLARE @SQL_CHECK NVARCHAR(MAX)
SET @SQL=N'SELECT @ROW_JOIN=('+@SQL_SEL+@SQL_FRM+@SQL_WHR+')'
SET @SQL_CHECK='SELECT COUNT(*) '+@SQL_FRM+REPLACE(REPLACE(@SQL_WHR,'=','<>'),' AND ',' OR ')
--PRINT @SQL
EXEC SP_EXECUTESQL @SQL,N'@ROW_JOIN INT OUT',@ROW_JOIN OUT


IF @PK_COUNT>0 SET @SQL=N'SELECT @ROW_ODS=(SELECT COUNT(*) FROM ODSDB.odsdba.'+@TABLE_NAME+')';
IF @PK_COUNT=0 SET @SQL=N'SELECT @ROW_ODS=(SELECT COUNT(*) FROM (SELECT DISTINCT * FROM ODSDB.odsdba.'+@TABLE_NAME+') AS A)';
EXEC SP_EXECUTESQL @SQL,N'@ROW_ODS INT OUT',@ROW_ODS OUT

IF @PK_COUNT>0 SET @SQL=N'SELECT @ROW_TEST=(SELECT COUNT(*) FROM TESTDB.odsdba.'+@TABLE_NAME+')';
IF @PK_COUNT=0 SET @SQL=N'SELECT @ROW_TEST=(SELECT COUNT(*) FROM (SELECT DISTINCT * FROM TESTDB.odsdba.'+@TABLE_NAME+') AS A )';

EXEC SP_EXECUTESQL @SQL,N'@ROW_TEST INT OUT',@ROW_TEST OUT

IF EXISTS(SELECT * FROM ODSDB.ODSDBA.CHK_TABLE WHERE TABLE_NAME=@TABLE_NAME)
  BEGIN    --此TABLE已做過測試則update
    UPDATE A
    SET TABLE_NAME=@TABLE_NAME
       ,CT_JOIN=@ROW_JOIN
       ,CT_ODS=@ROW_ODS
       ,CT_TEST=@ROW_TEST
       ,ISPK=CASE WHEN @PK_COUNT>0 THEN 'Y' ELSE 'N' END
       ,[MESSAGE]=CASE WHEN @ROW_JOIN<>@ROW_ODS OR @ROW_ODS<>@ROW_TEST OR @ROW_JOIN<>@ROW_TEST THEN '比對錯誤，請檢查表格'+@TABLE_NAME 
                ELSE @TABLE_NAME+'比對正確' END
       ,T_SQL=@SQL_CHECK
       ,RUN_TIME=GETDATE()
    FROM ODSDB.odsdba.CHK_TABLE A
    WHERE TABLE_NAME=@TABLE_NAME
  END
  ELSE
  BEGIN  --此TABLE之前未做過測試 insert
    INSERT INTO ODSDB.odsdba.CHK_TABLE
    SELECT @TABLE_NAME,@ROW_JOIN,@ROW_ODS,@ROW_TEST,CASE WHEN @PK_COUNT>0 THEN 'Y' ELSE 'N' END,
           CASE WHEN @ROW_JOIN<>@ROW_ODS OR @ROW_ODS<>@ROW_TEST OR @ROW_JOIN<>@ROW_TEST THEN '比對錯誤，請檢查表格'+@TABLE_NAME 
                ELSE @TABLE_NAME+'比對正確' END,@SQL_CHECK,GETDATE() 
  END

GOTO EXIT_STEP

NAME_ERROR_STEP:
  SELECT @TABLE_NAME+' 名稱錯誤,請檢查'

EXIT_STEP:






