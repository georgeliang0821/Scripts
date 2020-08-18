if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_ACFFPDPERF_TXFFMAT_MM_DW]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[sp_ACFFPDPERF_TXFFMAT_MM_DW]
go


CREATE PROCEDURE sp_ACFFPDPERF_TXFFMAT_MM_DW
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
-- This MNT Date  : 2003/9/19

/*
Comment  : ��� - ���~�����������
Filter   : TX_DT >=SQL("@ETL_BEGIN_DATE") AND TX_DT<=SQL("@ETL_END_DATE") AND CANCEL_FLG="N"
InsUpd   : INSERT
Join Cond: 
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
    FROM TXFFMAT AS src
    WHERE src.TX_DT >= @ETL_BEGIN_DATE AND src.TX_DT <= @ETL_END_DATE;

    -- �p�� @SRC_SEL_CNT
    SELECT @SRC_SEL_CNT = COUNT(*)
    FROM TXFFMAT AS src
    WHERE src.TX_DT >= @ETL_BEGIN_DATE 
        AND src.TX_DT <= @ETL_END_DATE 
        AND src.CANCEL_FLG = 'N'
 ;

    -- ��s XSTATUS
    EXEC [dbo].[sp_XStatusStart] @BATCH_NO, @JOB_STAGE, @JOB_FLOW, @JOB_SEQ, @ETL_BEGIN_DATE, @ETL_END_DATE,
    'TXFFMAT', 'ACFFPDPERF', @JOB_START_TIME, @SRC_CNT, @SRC_SEL_CNT, @FLT_CNT output, @BATCH_CNT output
END;









-------------------------------------------------------------------------------
-- ���Ҧ��}�l
-------------------------------------------------------------------------------
PRINT 'Batch Mode : Start';
IF @RUN_MODE <> 'TEST' BEGIN
    BEGIN TRAN
END;

-- Update �{������ ------------------------------------
-- Skipped by Insert/Update indicator.


DELETE FROM ACFFPDPERF 
WHERE CYC_DT >= @ETL_BEGIN_DATE
      AND CYC_DT <= @ETL_END_DATE

-- Insert �s������ ------------------------------------
INSERT INTO ACFFPDPERF(CYC_DT, ACCT_DWNO, PROD_DWCD, CYC_CAT,  PROD_CD , MAT_QTY, NTD_MAT_AMT, NTD_MAT_BUY_AMT, NTD_MAT_SELL_AMT, NTD_TX_FEE, NTD_TX_FEE_DISC, NTD_TX_OTHER_EXP, NTD_NON_TX_FEE, NTD_NON_TX_FEE_DISC, NTD_NON_TX_OTHER_EXP, NTD_REAL_PROFIT, LST_MNT_DT, EFF_DT, DW_LST_MNT_DT, DW_LST_MNT_SRC)
SELECT 
    /* CYC_DT= */ (@ETL_BEGIN_DATE) as CYC_DT
    ,/* ACCT_DWNO= */ src.ACCT_DWNO as ACCT_DWNO
    ,/* PROD_DWCD= */ src.PROD_DWCD as PROD_DWCD
    ,/* CYC_CAT= */ 'MM' as CYC_CAT
    ,/* PROD_CD= */ src.PROD_CD 
 --   ,/* MAT_CNT= */ ( SELECT COUNT(DISTINCT CONVERT(CHAR,TX_DT)+TRANS_ID) FROM TXFFMAT SRC WHERE SRC.ACCT_DWNO=A.ACCT_DWNO AND SRC.PROD_DWCD=A.PROD_DWCD AND REPLY_DT BETWEEN @ETL_BEGIN_DATE AND @ETL_END_DATE AND TX_CD IN ('1','2') AND CANCEL_FLG='N') as MAT_CNT
    ,/* MAT_QTY= */ (SUM(MAT_QTY)) as MAT_QTY
    ,/* NTD_MAT_AMT= */ (SUM(NTD_MAT_AMT)) as NTD_MAT_AMT
    ,/* NTD_MAT_BUY_AMT= */ (SUM(CASE WHEN BUY_SELL_FLG='B' THEN NTD_MAT_AMT ELSE 0 END)) as NTD_MAT_BUY_AMT
    ,/* NTD_MAT_SELL_AMT= */ (SUM(CASE WHEN BUY_SELL_FLG='S' THEN NTD_MAT_AMT ELSE 0 END)) as NTD_MAT_SELL_AMT
    ,/* NTD_TX_FEE= */ (SUM(NTD_TX_FEE)) as NTD_TX_FEE
    ,/* NTD_TX_FEE_DISC= */ (SUM(NTD_TX_FEE_DISC)) as NTD_TX_FEE_DISC
    ,/* NTD_TX_OTHER_EXP= */ (SUM(NTD_TX_OTHER_EXP)) as NTD_TX_OTHER_EXP
    ,/* NTD_NON_TX_FEE= */ (SUM(NTD_NON_TX_FEE)) as NTD_NON_TX_FEE
    ,/* NTD_NON_TX_FEE_DISC= */ (SUM(NTD_NON_TX_FEE_DISC)) as NTD_NON_TX_FEE_DISC
    ,/* NTD_NON_TX_OTHER_EXP= */ (SUM(NTD_NON_TX_OTHER_EXP)) as NTD_NON_TX_OTHER_EXP
    ,/* NTD_REAL_PROFIT= */ (SUM(NTD_REAL_PROFIT)) as NTD_REAL_PROFIT
    ,/* LST_MNT_DT= */ @ETL_END_DATE as LST_MNT_DT
    ,/* EFF_DT= */ @ETL_END_DATE AS EFF_DT
    ,/* DW_LST_MNT_DT= */ (@JOB_START_TIME) as DW_LST_MNT_DT
    ,/* DW_LST_MNT_SRC= */ 'TXFFMAT' as DW_LST_MNT_SRC
    FROM TXFFMAT AS SRC
    WHERE src.TX_DT >= @ETL_BEGIN_DATE 
         AND src.TX_DT <= @ETL_END_DATE 
         AND src.CANCEL_FLG = 'N'
   GROUP BY SRC.ACCT_DWNO , SRC.PROD_DWCD  , SRC.PROD_CD
   
;


SELECT @ERR_NO = @@ERROR, @INS_CNT = @@ROWCOUNT;
IF @ERR_NO<>0 GOTO BATCH_ERR_HANDLE;



UPDATE A
         SET A.MAT_CNT= ( SELECT COUNT(DISTINCT CONVERT(CHAR,TX_DT)+TRANS_ID) FROM TXFFMAT SRC WHERE SRC.ACCT_DWNO=A.ACCT_DWNO AND SRC.PROD_DWCD=A.PROD_DWCD AND REPLY_DT BETWEEN @ETL_BEGIN_DATE AND @ETL_END_DATE AND TX_CD IN ('1','2') AND CANCEL_FLG='N') 
    FROM ACFFPDPERF AS A , TXFFMAT AS SRC  
 WHERE A.CYC_DT = @ETL_BEGIN_DATE 
      AND A.ACCT_DWNO  = SRC.ACCT_DWNO 
      AND A.PROD_DWCD  = SRC.PROD_DWCD
      AND SRC.CANCEL_FLG = 'N'
      AND SRC.TX_DT >= @ETL_BEGIN_DATE 
      AND SRC.TX_DT <= @ETL_END_DATE



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
-- �{������ sp_ACFFPDPERF_TXFFMAT_MM_DW
------------------------------
IF @ERR_NO<>0 RAISERROR(@ERR_NO, 16, 1);
RETURN(@ERR_NO)
GO


