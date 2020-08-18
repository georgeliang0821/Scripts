if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_ACFFPERF_ACFFHOLDH_MM_DW]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[sp_ACFFPERF_ACFFHOLDH_MM_DW]
go


CREATE PROCEDURE sp_ACFFPERF_ACFFHOLDH_MM_DW
    @BATCH_NO       VARCHAR(10),        --XBATCHFLOW.BATCH_NO
    @JOB_STAGE      CHAR(3),            --XBATCHFLOW.JOB_STAGE
    @JOB_FLOW       INTEGER,            --XBATCHFLOW.JOB_FLOW
    @JOB_SEQ        INTEGER,            --XBATCHFLOW.JOB_SEQ
    @ETL_BEGIN_DATE DATETIME,           --�@�~�_�l���
    @ETL_END_DATE   DATETIME,           --�@�~�_�l���
    @RUN_MODE       VARCHAR(7)          --�Ұʪ��A(Normal/Restart)
AS

-- �H�U�� XSTATUS �����ܼ�
DECLARE @JOB_START_TIME datetime        --�{���_�l�ɶ�
DECLARE @LOOKUP_IND     varchar(1)      --�O�_�����X�s�N�X�ܥN�X��(T/F)
DECLARE @BATCH_CNT      decimal(10)     --�ӷ���Ƶ���(By XBHDATE2)
DECLARE @SRC_CNT        decimal(10)     --�ӷ���Ƶ���(By Count)
DECLARE @INS_CNT        decimal(10)     --�s�W��Ƶ���
DECLARE @UPD_CNT        decimal(10)     --��s��Ƶ���
DECLARE @FLT_CNT        decimal(10)     --�z�ﵧ��(Filter�ñ�������)
DECLARE @SRC_SEL_CNT    decimal(10)     --�ӷ����Filter�d�U�Ӫ�����
DECLARE @DIFF_CNT       decimal(10)     --�t������

-- �H�U�� ���汱�� �����ܼ�
DECLARE @ERR_NO         int             --���~�N�X
DECLARE @F_UPD_XSTATUS  char(1)         --�O�_��sXSTATUS��ƪ�(T=TRUE,F=FALSE)
DECLARE @F_UPD_ERRLOG   char(1)         --�O�_��sERRLOG��ƪ� (T=TRUE,F=FALSE)
DECLARE @F_UPD_SRC_CNT  char(1)         --�]�wXSTATUS.SRC_CNT�O�_����(Y=Yes,N=No)
DECLARE @F_MNT_CODE_TBL char(1)         --�O�_����s�������N�X��(T=TRUE,F=FALSE)
DECLARE @F_LOOKUP_FLAG  char(1)         --Lookup�ĥ|�ӰѼơG
                                        --  T(�N�s�N�X�g�J�N�X��A�ò��ͬ���)
                                        --  F(���g�J�N�X��A�����ͬ���)
                                        --  N(���B�z)
------------------------------
-- ��������
------------------------------
-- Excel File     : Polaris DW Mapping V1.2.xls
-- Format Version : V1.2
-- Rule Version   : V1.2
-- Data Source    : DW
-- Last MNT Date  : 
-- This MNT Date  : 2003/9/22

/*
Comment  : �b�� - ���~����w�s���v��
Filter   : SRC.CYC_DT>= sql("@ETL_BEGIN_DATE")  AND SRC.CYC_DT<= sql("@ETL_END_DATE")
InsUpd   : Update
Join Cond: A.ACCT_DWNO = SRC.ACCT_DWNO AND A.CYC_DT=sql("@ETL_BEGIN_DATE")
*/

------------------------------
-- �{���}�l
------------------------------
-- ����X��
SET @F_UPD_XSTATUS = 'T';
SET @F_UPD_ERRLOG = 'T';
SET @F_UPD_SRC_CNT = 'Y'
SET @F_MNT_CODE_TBL = 'T';

-- �b���ռҦ��U�A���L XSTATUS, ERRLOG ����s
IF UPPER(@RUN_MODE) = 'TEST' BEGIN
    SET @F_UPD_XSTATUS = 'T';
    SET @F_UPD_ERRLOG = 'T';
END;

SET @JOB_START_TIME = GetDate();
SET @INS_CNT = 0;
SET @UPD_CNT = 0;
SET @LOOKUP_IND = 'F';  --default

------------------------------
-- �NXSTATUS��s�� '���椤',��
-- �p��BATCH_CNT, SRC_CNT, FLT_CNT
------------------------------
IF @F_UPD_XSTATUS = 'T' BEGIN

    -- �p�� @SRC_CNT
    SELECT @SRC_CNT = COUNT(*)
    FROM ACFFHOLDH AS src
    WHERE src.CYC_DT >= @ETL_BEGIN_DATE AND src.CYC_DT <= @ETL_END_DATE;

    -- �p�� @SRC_SEL_CNT
    SELECT @SRC_SEL_CNT = COUNT(*)
    FROM ACFFHOLDH AS src
    WHERE SRC.CYC_DT >= @ETL_BEGIN_DATE AND SRC.CYC_DT <= @ETL_END_DATE
;

    -- ��s XSTATUS
    EXEC [dbo].[sp_XStatusStart] @BATCH_NO, @JOB_STAGE, @JOB_FLOW, @JOB_SEQ, @ETL_BEGIN_DATE, @ETL_END_DATE,
    'ACFFHOLDH', 'ACFFPERF', @JOB_START_TIME, @SRC_CNT, @SRC_SEL_CNT, @FLT_CNT output, @BATCH_CNT output
END;

-------------------------------------------------------------------------------
-- ���Ҧ��}�l
-------------------------------------------------------------------------------
PRINT 'Batch Mode : Start';
IF @RUN_MODE <> 'TEST' BEGIN
    BEGIN TRAN
END;

---- �̤j�w�s����  �A�̤p�w�s���� �A�����w�s���� �A�̤j�w�s���ȡA�̤p�w�s���� �A �����w�s����
  SELECT  ACCT_DWNO,   CYC_DT,
                 SUM(ISNULL(NTD_COST_AMT,0)) AS MKT_VALUE1 
    --             SUM(ISNULL(CB_QTY*TRADE_NTD_RATE*NAV_PRICE,0)) AS MKT_VALUE2 
     INTO #SRC1
     FROM ACFFHOLDH   AS SRC  
  WHERE  SRC.CYC_DT>=@ETL_BEGIN_DATE 
        AND SRC.CYC_DT<=@ETL_END_DATE 
   GROUP BY ACCT_DWNO, CYC_DT

SELECT ACCT_DWNO,
               MAX(B.MKT_VALUE1) MAX_COST_AMT, 
               MIN(B.MKT_VALUE1)  MIN_COST_AMT,
               SUM(B.MKT_VALUE1)   SUM_COST_AMT,
--               MAX(B.MKT_VALUE2) MAX_HOLD_AMT,
--               MIN(B.MKT_VALUE2)  MIN_HOLD_AMT, 
--               SUM(B.MKT_VALUE2) SUM_HOLD_AMT,
               COUNT( DISTINCT CYC_DT)  AS HOLD_DAYS
    INTO  #SRC2
    FROM #SRC1 AS B
 GROUP BY ACCT_DWNO 


-- Update �{������ ------------------------------------
 UPDATE A
    SET A.NTD_MAX_COST_AMT = SRC1.MAX_COST_AMT
    ,A.NTD_MIN_COST_AMT = ( CASE WHEN HOLD_DAYS = DAY(@ETL_END_DATE) THEN SRC1.MIN_COST_AMT ELSE 0 END) 
    ,A.NTD_AVG_COST_AMT = ( SRC1.SUM_COST_AMT ) / DAY(@ETL_END_DATE)
--   , A.NTD_MAX_HOLD_AMT = SRC1.MAX_HOLD_AMT
--   , A.NTD_MIN_HOLD_AMT = ( CASE WHEN HOLD_DAYS = DAY(@ETL_END_DATE) THEN SRC1.MIN_HOLD_AMT ELSE 0 END) 
--   , A.NTD_AVG_HOLD_AMT = ( SRC1.SUM_HOLD_AMT ) / DAY(@ETL_END_DATE)
   , A.LST_MNT_DT = (@ETL_END_DATE) 
    ,A.DW_LST_MNT_DT = (@JOB_START_TIME)
    ,A.DW_LST_MNT_SRC = 'ACFFHOLDH'
    FROM ACFFPERF AS A, #SRC2  AS SRC1
    WHERE  A.CYC_DT >= @ETL_BEGIN_DATE
          AND A.CYC_DT <= @ETL_END_DATE
          AND A.ACCT_DWNO = SRC1.ACCT_DWNO 
;


SELECT @ERR_NO = @@ERROR, @UPD_CNT = @@ROWCOUNT;
IF @ERR_NO<>0 GOTO BATCH_ERR_HANDLE;


DROP TABLE #SRC1
DROP TABLE #SRC2



-- Insert �s������ ------------------------------------
-- Skipped by Insert/Update indicator.



-- Update ���Ψ�Target Table�����---------------------
-- No such fields




------------------------------
-- ���Ҧ��B�z���\
------------------------------
PRINT 'Batch Mode : Finished Successfully';
PRINT '';
IF @RUN_MODE <> 'TEST' BEGIN
    COMMIT TRAN;
END;
GOTO WRITE_LOG;



-------------------------------------------------------------------------------
-- ���Ҧ����~�B�z
   BATCH_ERR_HANDLE:
-------------------------------------------------------------------------------
PRINT 'Batch Mode : Failure';
PRINT '';
IF @RUN_MODE <> 'TEST' BEGIN
    ROLLBACK TRAN;
END;










               
------------------------------
-- ���浲�G����
   WRITE_LOG:
------------------------------
IF @F_UPD_XSTATUS = 'T' BEGIN

    -- �p�� @DIFF_CNT
    IF @F_UPD_SRC_CNT='Y' BEGIN
        SELECT @DIFF_CNT = @SRC_CNT -(@INS_CNT + @UPD_CNT + @FLT_CNT);
    END ELSE BEGIN
        SELECT @DIFF_CNT = @BATCH_CNT -(@INS_CNT + @UPD_CNT + @FLT_CNT);
    END;

    -- ��s XSTATUS
    EXEC [dbo].[sp_XStatusFinish] @BATCH_NO, @JOB_STAGE, @JOB_FLOW, @JOB_SEQ, @JOB_START_TIME,   @INS_CNT, @UPD_CNT, @DIFF_CNT, @LOOKUP_IND, @ERR_NO;

END;

print '@SRC_CNT     =' + STR(@SRC_CNT);
print '@SRC_SEL_CNT =' + STR(@SRC_SEL_CNT);
print '@INS_CNT     =' + STR(@INS_CNT);
print '@UPD_CNT     =' + STR(@UPD_CNT);
print '@INS+@UPD    =' + STR(@INS_CNT + @UPD_CNT);

------------------------------
-- �{������ sp_ACFFPERF_ACFFHOLDH_MM_DW
------------------------------
IF @ERR_NO<>0 RAISERROR(@ERR_NO, 16, 1);
RETURN(@ERR_NO)
GO


