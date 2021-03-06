
--判斷料週期

DECLARE @TABLENAME CHAR(40)
DECLARE @CYCLE CHAR(1)
IF RIGHT(RTRIM(@TABLENAME),3) IN ('_MS','_MA','_MH','_MW') OR LEFT(LTRIM(@TABLENAME),6) = 'ODSMS_' 
BEGIN
   @CYCLE = 'M'
END ELSE BEGIN
   @CYCLE = 'D'  
END

--判斷更新方式


--Type1:MD_ODS_INFO
--Rule:1.以XJOBDETAILL之JOB_NAME欄位取中間之名稱找出其對應之ODS TABLE NAME,及其PROCESS_TYPE
--     2.PROCESS_TYPE為D即為全部更新(C),反之,則為星期五全部更新,一至四做異動更新(CD)
USE ISMD
GO
SELECT CASE WHEN S1.PROCESS_TYPE = 'D' THEN 'C' ELSE 'CD' END,CASE WHEN S2.UN_FG = 'Y' THEN 'ODS_UN_'+ SUBSTRING( RTRIM(dbo.INSTR(S1.JOB_NAME,'_',2)), 3, LEN(RTRIM(dbo.INSTR(S1.JOB_NAME,'_',2) ))-2) ELSE 'ODS_'+LEFT(S1.JOB_STAGE,LEN(RTRIM(S1.JOB_STAGE))-1)+ '_'+SUBSTRING( RTRIM(dbo.INSTR(S1.JOB_NAME,'_',2)), LEN(RTRIM(S1.JOB_STAGE)),LEN(RTRIM(dbo.INSTR(S1.JOB_NAME,'_',2))) - LEN(RTRIM(S1.JOB_STAGE))+1 ) END  
FROM (
SELECT MAX(DATACAT) DATACAT,MAX(JOB_STAGE) JOB_STAGE,MAX(PROCESS_TYPE) AS PROCESS_TYPE,JOB_NAME
FROM ODSDBA.XJOBDETAIL
WHERE JOB_LOCATION = '\ODSDB'
GROUP BY JOB_NAME
      ) S1
,ODSDBA.XFLOWDETAIL S2
WHERE S1.DATACAT= S2.DATACAT

--Type2:MD_DWBASIS_INFO
--Rule:1.以TALBE NAME判斷,(1)若為monthly snapshot或daily snapshot則為異動(D)
--                        (2)若為CS TABLE為WORKING TABLE則為全部重做(C)
--                        (3)其它為星期五全部更新,一至四做異動更新(CD)
DECLARE @TABLENAME CHAR(40)
DECLARE @REFRESH_TYPE CHAR(3)
IF RIGHT(RTRIM(@TABLENAME),3) IN ('_MS','_MA','_MH','_MW','DH') OR LEFT(LTRIM(@TABLENAME),6) = 'ODSMS_' OR LEFT(RTRIM(@TABLENAME),3) = 'TX_'
BEGIN
   @REFRESH_TYPE = 'D'
END ELSE BEGIN
  IF LEFT(RTRIM(@TABLENAME),3) IN ('CS_') OR RIGHT(RTRIM(@TABLENAME),3) = '_WK'
   BEGIN
     @REFRESH_TYPE = 'C'  
   END ELSE BEGIN
     @REFRESH_TYPE = 'CD' 
   END
END


--找MS
SELECT JOB_NAME,CASE WHEN S2.UN_FG = 'Y' THEN 'ODSMS_UN_'+ SUBSTRING( RTRIM(dbo.INSTR(S1.JOB_NAME,'_',3)), 9, LEN(RTRIM(dbo.INSTR(S1.JOB_NAME,'_',3) ))-8) ELSE 'ODSMS_'+LEFT(S1.JOB_STAGE,LEN(RTRIM(S1.JOB_STAGE))-1)+ '_'+SUBSTRING( RTRIM(dbo.INSTR(S1.JOB_NAME,'_',3)), LEN(RTRIM(S1.JOB_STAGE))+5,LEN(RTRIM(dbo.INSTR(S1.JOB_NAME,'_',3))) - LEN(RTRIM(S1.JOB_STAGE))+1 ) END
FROM (
SELECT MAX(DATACAT) DATACAT,MAX(JOB_STAGE) JOB_STAGE,MAX(PROCESS_TYPE) AS PROCESS_TYPE,JOB_NAME

FROM ODSDBA.XJOBDETAIL
WHERE JOB_LOCATION = 'ODSDB' 
  AND JOB_NAME LIKE 'SP_INS_ODSMS%'
GROUP BY JOB_NAME   ) S1
     ,ISMD.ODSDBA.XFLOWDETAIL S2
WHERE S2.DATACAT = S1.DATACAT