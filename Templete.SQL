if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_CB_DT_TMP_UN_DEDATE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[sp_CB_DT_TMP_UN_DEDATE]
go


CREATE PROCEDURE sp_CB_DT_TMP_UN_DEDATE
    @BATCH_NO       VARCHAR(10),        --XBATCHFLOW.BATCH_NO
    @JOB_STAGE      CHAR(3),            --XBATCHFLOW.JOB_STAGE
    @JOB_FLOW       INTEGER,            --XBATCHFLOW.JOB_FLOW
    @JOB_SEQ        INTEGER,            --XBATCHFLOW.JOB_SEQ
    @ETL_BEGIN_DATE DATETIME,           --作業起始日期
    @ETL_END_DATE   DATETIME,           --作業起始日期
    @RUN_MODE       VARCHAR(7)          --啟動狀態(Normal/Restart)
AS

-- 以下為 XSTATUS 相關變數
DECLARE @JOB_START_TIME datetime        --程式起始時間
DECLARE @LOOKUP_IND     varchar(1)      --是否有產出新代碼至代碼表(T/F)
DECLARE @BATCH_CNT      decimal(10)     --來源資料筆數(By XBHDATE2)
DECLARE @SRC_CNT        decimal(10)     --來源資料筆數(By Count)
DECLARE @INS_CNT        decimal(10)     --新增資料筆數
DECLARE @UPD_CNT        decimal(10)     --更新資料筆數
DECLARE @FLT_CNT        decimal(10)     --篩選筆數(Filter踼掉的筆數)
DECLARE @SRC_SEL_CNT    decimal(10)     --來源資料Filter留下來的筆數
DECLARE @DIFF_CNT       decimal(10)     --差異筆數

-- 以下為 執行控制 相關變數
DECLARE @ERR_NO         int             --錯誤代碼
DECLARE @F_UPD_XSTATUS  char(1)         --是否更新XSTATUS資料表(T=TRUE,F=FALSE)
DECLARE @F_UPD_ERRLOG   char(1)         --是否更新ERRLOG資料表 (T=TRUE,F=FALSE)
DECLARE @F_UPD_SRC_CNT  char(1)         --設定XSTATUS.SRC_CNT是否有效(Y=Yes,N=No)
DECLARE @F_MNT_CODE_TBL char(1)         --是否先更新相關的代碼表(T=TRUE,F=FALSE)
DECLARE @F_LOOKUP_FLAG  char(1)         --Lookup第四個參數：
                                        --  T(將新代碼寫入代碼表，並產生紀錄)
                                        --  F(不寫入代碼表，但產生紀錄)
                                        --  N(不處理)
------------------------------
-- 版本控制
------------------------------
-- Excel File     : LBOT DWBasisDB Dimension Mapping v1.6_test1.XLS
-- Format Version : V0
-- Rule Version   : V0
-- Data Source    : SA
-- Last MNT Date  : 
-- This MNT Date  : 2005/1/17

/*
Comment  : 
Filter   : 
InsUpd   : INSERT/UPDATE
Join Cond: 
*/

------------------------------
-- 程式開始
------------------------------
-- 控制旗標
SET @F_UPD_XSTATUS = 'T';
SET @F_UPD_ERRLOG = 'T';
SET @F_UPD_SRC_CNT = 'N'
SET @F_MNT_CODE_TBL = 'T';

-- 在測試模式下，略過 XSTATUS, ERRLOG 的更新
IF UPPER(@RUN_MODE) = 'TEST' BEGIN
    SET @F_UPD_XSTATUS = 'T';
    SET @F_UPD_ERRLOG = 'T';
END;

SET @JOB_START_TIME = GetDate();
SET @INS_CNT = 0;
SET @UPD_CNT = 0;
SET @LOOKUP_IND = 'F';  --default

------------------------------
-- 將XSTATUS更新為 '執行中',並
-- 計算BATCH_CNT, SRC_CNT, FLT_CNT
------------------------------
IF @F_UPD_XSTATUS = 'T' BEGIN

    -- 計算 @SRC_CNT
    SELECT @SRC_CNT = COUNT(*)
    FROM ME-LBOT.odsdba.TMP_UN_DEDATE AS src
    ;

    -- 計算 @SRC_SEL_CNT
    SELECT @SRC_SEL_CNT = COUNT(*)
    FROM ME-LBOT.odsdba.TMP_UN_DEDATE AS src
    ;

    -- 更新 XSTATUS
    EXEC [dbo].[sp_XStatusStart] @BATCH_NO, @JOB_STAGE, @JOB_FLOW, @JOB_SEQ, @ETL_BEGIN_DATE, @ETL_END_DATE,
    'TMP_UN_DEDATE', 'CB_DT', @JOB_START_TIME, @SRC_CNT, @SRC_SEL_CNT, @FLT_CNT output, @BATCH_CNT output
END;









-------------------------------------------------------------------------------
-- 整批模式開始
-------------------------------------------------------------------------------
PRINT 'Batch Mode : Start';
IF @RUN_MODE <> 'TEST' BEGIN
    BEGIN TRAN
END;

-- Update 現有紀錄 ------------------------------------
UPDATE A
    SET A.DT_CHAR = CAST(TBSYY AS VARCHAR) + RIGHT('00' + CAST(TBSMM AS VARCHAR), 2) + RIGHT('00' + CAST(TBSDD AS VARCHAR), 2)
    ,A.WEEK_DY = src.WEEKDY
    ,A.WEEK_NO = DATEPART(WEEK,a.DATADT)
    ,A.YR = src.TBSYY
    ,A.MN = RIGHT('00' + CAST(TBSMM AS VARCHAR), 2)
    ,A.DY_IN_MN = RIGHT('00' + CAST(TBSDD AS VARCHAR), 2)
    ,A.DY_IN_YR = DATEPART(DY,a.DATADT)
    ,A.SEASON = DATEPART(QQ,a.DATADT)
    ,A.SEMI_YR_NM = CASE WHEN DATEPART(QQ,a.DATADT) = 1 OR 2 THEN 上半年'  ELSE '下半年' END
    ,A.HOLIDY_FG = src.HOLIDY
    ,A.HOLIDY_DY = DATEDIFF(DD,a.TBSDT,a.NBSDT)
    ,A.CYC_BEG = a.DATADT
    ,A.CYC_END = a.DATADT
    ,A.BBOW_FG = CASE WHEN (DATEPART(WK,a.TBSDT) <> DATEPART(WK,a.LBSDT)) AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END
    ,A.BEOW_FG = CASE WHEN (DATEPART(WK,a.TBSDT) <> DATEPART(WK,a.NBSDT)) AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END
    ,A.BBOM_FG = CASE WHEN( DATEPART(MM,a.LBSDT) <> DATEPART(MM,a.TBSDT) )AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END
    ,A.BEOM_FG = CASE WHEN DATEPART(MM,a.NBSDT) <> DATEPART(MM,a.TBSDT) AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END
    ,A.BBOQ_FG = CASE WHEN (DATEPART(QQ,a.TBSDT) <> DATEPART(QQ,a.LBSDT))  AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END
    ,A.BEOQ_FG = CASE WHEN (DATEPART(QQ,a.TBSDT) <> DATEPART(QQ,a.NBSDT))  AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END
    ,A.BBOY_FG = CASE WHEN (DATEPART(YY,a.TBSDT) <> DATEPART(YY,a.LBSDT))  AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END
    ,A.BEOY_FG = CASE WHEN (DATEPART(YY,a.TBSDT) <> DATEPART(YY,a.NBSDT))  AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END
    ,A.EOM_FG = CASE WHEN FD-YEARDAY-TBSDY = FD-YEARDAY-TMNDY THEN 'Y' ELSE 'N' END
    ,A.TBSDT = CONVERT(DATETIME,CAST(FD-YEARDAY-TBSDY+19110000 AS VARCHAR(8))
    ,A.LBSDT = CONVERT(DATETIME,CAST(FD-YEARDAY-LBSDY+19110000 AS VARCHAR(8))
    ,A.NBSDT = CONVERT(DATETIME,CAST(FD-YEARDAY-NBSDY+19110000 AS VARCHAR(8))
    ,A.NNBSDT = CONVERT(DATETIME,CAST(FD-YEARDAY-NNBSDY+19110000 AS VARCHAR(8))
    ,A.LBSDY = src.LDYCNT
    ,A.NBSDY = src.NDYCNT
    ,A.NNBZDY = src.NNDCNT
    ,A.DYCNTEOM = DATEDIFF(DD,a.TBSDT,a.TMNEDT)
    ,A.NDYCNTTM = MIN(a.DYCNTEOM,a.NBSDY)+1
    ,A.L2MNBDT =  DATEADD(MM, - 2, DATEADD(DD, - (TBSDD - 1), a.DATADT)) 
    ,A.L2MNEDT = DATEADD(DD,-1, DATEADD(MM, - 1, DATEADD(DD, - (TBSDD - 1), a.DATADT)) )
    ,A.L2MNEDYS = CONVERT(VARCHAR(2),DATEADD(DD,-1, DATEADD(MM, - 1, DATEADD(DD, - (TBSDD - 1), a.DATADT)) ),106)
    ,A.LMNBDT = DATEADD(MM, - 1, DATEADD(DD, - (TBSDD - 1), a.DATADT))
    ,A.LMNEDT = CONVERT(DATETIME,LMNDY)
    ,A.LMNEDYS = RIGHT(CONVERT(DATETIME,LMNDY),2)
    ,A.TMNBDT = DATEADD(DD,-(TBSDD-1),a.DATADT)
    ,A.TMNEDT = CONVERT(DATETIME,CAST(TMNDY AS VARCHAR(8)))
    ,A.TMNDYS = RIGHT(TMNDY,2)
    ,A.FNBSDT = CONVERT(DATETIME,CAST(FNBSDY AS VARCHAR(8)))
    ,A.TQBDT = CASE WHEN a.SEASON = 1 THEN CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0101') WHEN a.SEASON=2 THENCONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0401') WHEN a.SEASON=3 THEN CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0701') ELSE CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'1001')
    ,A.TQEDT = CASE WHEN a.SEASON = 1 THEN CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0301') WHEN a.SEASON=2 THENCONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0601') WHEN a.SEASON=3 THEN CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0901') ELSE CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'1201')
    ,A.TQDYS = CASE WHEN a.SEASON=1 THEN DATEDIFF(CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0101'),CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0331'))WHEN a.SEASON=2 THEN 90 WHEN a.SEASON=3 THEN 91 ELSE 91
    ,A.L1QBDT = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0101') WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0401') WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0701') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '1001')
    ,A.L1QEDT = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0301') WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0601') WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0901') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '1201')
    ,A.L1QDYS = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT))=1 THEN DATEDIFF(CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0101'),CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0331')WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT))=2 THEN 90 WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT))=3 THEN 91 ELSE 91 END
    ,A.L2QBDT = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-2,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-2,a.DATADT),112) + '0101') WHEN DATEPART(QUARTER,ADDDATE(QQ,-2,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-2,a.DATADT),112) + '0401') WHEN DATEPART(QUARTER,ADDDATE(QQ,-2,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-2,a.DATADT),112) + '0701') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-2,a.DATADT),112) + '1001') END
    ,A.L2QEDT = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ-2,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '0301') WHEN DATEPART(QUARTER,ADDDATE(QQ-2,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '0601') WHEN DATEPART(QUARTER,ADDDATE(QQ-2,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '0901') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '1201') END
    ,A.L2QDYS = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ-2,a.DATADT))=1 THEN DATEDIFF(CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '0101'),CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '0331')WHEN DATEPART(QUARTER,ADDDATE(MM,-6,a.DATADT))=2 THEN 90 WHEN DATEPART(QUARTER,ADDDATE(MM,-6,a.DATADT))=3 THEN 91 ELSE 91 END
    ,A.L3QBDT = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0101') WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0401') WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0701') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '1001') END
    ,A.L3QEDT = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0301') WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0601') WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0901') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '1201') END
    ,A.L3QDYS = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-3,a.DATADT))=1 THEN DATEDIFF(CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-3,a.DATADT),112) + '0101'),CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-3,a.DATADT),112) + '0331')WHEN DATEPART(QUARTER,ADDDATE(QQ,-3,a.DATADT))=2 THEN 90 WHEN DATEPART(QUARTER,ADDDATE(QQ,-3a.DATADT))=3 THEN 91 ELSE 91 END
    ,A.L4QBDT = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '0101') WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '0401') WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '0701') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '1001') END
    ,A.L4QEDT = CASE WHEN DATEPART(QUARTER,ADDDATE(MM,-6,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(MM,-6,a.DATADT),112) + '0301') WHEN DATEPART(QUARTER,ADDDATE(MM,-6,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(MM,-6,a.DATADT),112) + '0601') WHEN DATEPART(QUARTER,ADDDATE(MM,-6,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(MM,-6,a.DATADT),112) + '0901') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(MM,-6,a.DATADT),112) + '1201') END
    ,A.L4QDYS = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT))=1 THEN DATEDIFF(CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '0101'),CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '0331')WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT))=2 THEN 90 WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT))=3 THEN 91 ELSE 91 END
    ,A.L5QBDT = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0101') WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0401') WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0701') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '1001') END
    ,A.L5QEDT = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0301') WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0601') WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0901') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '1201') END
    ,A.L5QDYS = CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT))=1 THEN DATEDIFF(CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0101'),CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0331')WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT))=2 THEN 90 WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT))=3 THEN 91 ELSE 91 END
    ,A.LstSysDt = GETDATE()
    FROM CB_DT AS A
    JOIN ME-LBOT.odsdba.TMP_UN_DEDATE AS src on(
        A.DATADT = CONVERT(DATETIME, CAST(TBSYY AS VARCHAR) + RIGHT('00' + CAST(TBSMM AS VARCHAR), 2) + RIGHT('00' + CAST(TBSDD AS VARCHAR), 2))
    )
;
 
SELECT @ERR_NO = @@ERROR, @UPD_CNT = @@ROWCOUNT;
IF @ERR_NO<>0 GOTO BATCH_ERR_HANDLE;



-- Insert 新的紀錄 ------------------------------------
INSERT INTO CB_DT(DATADT, DT_CHAR, WEEK_DY, WEEK_NO, YR, MN, DY_IN_MN, DY_IN_YR, SEASON, SEMI_YR_NM, HOLIDY_FG, HOLIDY_DY, CYC_BEG, CYC_END, BBOW_FG, BEOW_FG, BBOM_FG, BEOM_FG, BBOQ_FG, BEOQ_FG, BBOY_FG, BEOY_FG, EOM_FG, TBSDT, LBSDT, NBSDT, NNBSDT, LBSDY, NBSDY, NNBZDY, DYCNTEOM, NDYCNTTM, L2MNBDT, L2MNEDT, L2MNEDYS, LMNBDT, LMNEDT, LMNEDYS, TMNBDT, TMNEDT, TMNDYS, FNBSDT, TQBDT, TQEDT, TQDYS, L1QBDT, L1QEDT, L1QDYS, L2QBDT, L2QEDT, L2QDYS, L3QBDT, L3QEDT, L3QDYS, L4QBDT, L4QEDT, L4QDYS, L5QBDT, L5QEDT, L5QDYS, LstSysDt)
SELECT 
    /* DATADT= */ CONVERT(DATETIME, CAST(TBSYY AS VARCHAR) + RIGHT('00' + CAST(TBSMM AS VARCHAR), 2) + RIGHT('00' + CAST(TBSDD AS VARCHAR), 2)) as DATADT
    ,/* DT_CHAR= */ CAST(TBSYY AS VARCHAR) + RIGHT('00' + CAST(TBSMM AS VARCHAR), 2) + RIGHT('00' + CAST(TBSDD AS VARCHAR), 2) as DT_CHAR
    ,/* WEEK_DY= */ src.WEEKDY as WEEK_DY
    ,/* WEEK_NO= */ DATEPART(WEEK,a.DATADT) as WEEK_NO
    ,/* YR= */ src.TBSYY as YR
    ,/* MN= */ RIGHT('00' + CAST(TBSMM AS VARCHAR), 2) as MN
    ,/* DY_IN_MN= */ RIGHT('00' + CAST(TBSDD AS VARCHAR), 2) as DY_IN_MN
    ,/* DY_IN_YR= */ DATEPART(DY,a.DATADT) as DY_IN_YR
    ,/* SEASON= */ DATEPART(QQ,a.DATADT) as SEASON
    ,/* SEMI_YR_NM= */ CASE WHEN DATEPART(QQ,a.DATADT) = 1 OR 2 THEN 上半年'  ELSE '下半年' END as SEMI_YR_NM
    ,/* HOLIDY_FG= */ src.HOLIDY as HOLIDY_FG
    ,/* HOLIDY_DY= */ DATEDIFF(DD,a.TBSDT,a.NBSDT) as HOLIDY_DY
    ,/* CYC_BEG= */ a.DATADT as CYC_BEG
    ,/* CYC_END= */ a.DATADT as CYC_END
    ,/* BBOW_FG= */ CASE WHEN (DATEPART(WK,a.TBSDT) <> DATEPART(WK,a.LBSDT)) AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END as BBOW_FG
    ,/* BEOW_FG= */ CASE WHEN (DATEPART(WK,a.TBSDT) <> DATEPART(WK,a.NBSDT)) AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END as BEOW_FG
    ,/* BBOM_FG= */ CASE WHEN( DATEPART(MM,a.LBSDT) <> DATEPART(MM,a.TBSDT) )AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END as BBOM_FG
    ,/* BEOM_FG= */ CASE WHEN DATEPART(MM,a.NBSDT) <> DATEPART(MM,a.TBSDT) AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END as BEOM_FG
    ,/* BBOQ_FG= */ CASE WHEN (DATEPART(QQ,a.TBSDT) <> DATEPART(QQ,a.LBSDT))  AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END as BBOQ_FG
    ,/* BEOQ_FG= */ CASE WHEN (DATEPART(QQ,a.TBSDT) <> DATEPART(QQ,a.NBSDT))  AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END as BEOQ_FG
    ,/* BBOY_FG= */ CASE WHEN (DATEPART(YY,a.TBSDT) <> DATEPART(YY,a.LBSDT))  AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END as BBOY_FG
    ,/* BEOY_FG= */ CASE WHEN (DATEPART(YY,a.TBSDT) <> DATEPART(YY,a.NBSDT))  AND HOLIDY <> 1 THEN 'Y' ELSE 'N' END as BEOY_FG
    ,/* EOM_FG= */ CASE WHEN FD-YEARDAY-TBSDY = FD-YEARDAY-TMNDY THEN 'Y' ELSE 'N' END as EOM_FG
    ,/* TBSDT= */ CONVERT(DATETIME,CAST(FD-YEARDAY-TBSDY+19110000 AS VARCHAR(8)) as TBSDT
    ,/* LBSDT= */ CONVERT(DATETIME,CAST(FD-YEARDAY-LBSDY+19110000 AS VARCHAR(8)) as LBSDT
    ,/* NBSDT= */ CONVERT(DATETIME,CAST(FD-YEARDAY-NBSDY+19110000 AS VARCHAR(8)) as NBSDT
    ,/* NNBSDT= */ CONVERT(DATETIME,CAST(FD-YEARDAY-NNBSDY+19110000 AS VARCHAR(8)) as NNBSDT
    ,/* LBSDY= */ src.LDYCNT as LBSDY
    ,/* NBSDY= */ src.NDYCNT as NBSDY
    ,/* NNBZDY= */ src.NNDCNT as NNBZDY
    ,/* DYCNTEOM= */ DATEDIFF(DD,a.TBSDT,a.TMNEDT) as DYCNTEOM
    ,/* NDYCNTTM= */ MIN(a.DYCNTEOM,a.NBSDY)+1 as NDYCNTTM
    ,/* L2MNBDT= */  DATEADD(MM, - 2, DATEADD(DD, - (TBSDD - 1), a.DATADT))  as L2MNBDT
    ,/* L2MNEDT= */ DATEADD(DD,-1, DATEADD(MM, - 1, DATEADD(DD, - (TBSDD - 1), a.DATADT)) ) as L2MNEDT
    ,/* L2MNEDYS= */ CONVERT(VARCHAR(2),DATEADD(DD,-1, DATEADD(MM, - 1, DATEADD(DD, - (TBSDD - 1), a.DATADT)) ),106) as L2MNEDYS
    ,/* LMNBDT= */ DATEADD(MM, - 1, DATEADD(DD, - (TBSDD - 1), a.DATADT)) as LMNBDT
    ,/* LMNEDT= */ CONVERT(DATETIME,LMNDY) as LMNEDT
    ,/* LMNEDYS= */ RIGHT(CONVERT(DATETIME,LMNDY),2) as LMNEDYS
    ,/* TMNBDT= */ DATEADD(DD,-(TBSDD-1),a.DATADT) as TMNBDT
    ,/* TMNEDT= */ CONVERT(DATETIME,CAST(TMNDY AS VARCHAR(8))) as TMNEDT
    ,/* TMNDYS= */ RIGHT(TMNDY,2) as TMNDYS
    ,/* FNBSDT= */ CONVERT(DATETIME,CAST(FNBSDY AS VARCHAR(8))) as FNBSDT
    ,/* TQBDT= */ CASE WHEN a.SEASON = 1 THEN CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0101') WHEN a.SEASON=2 THENCONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0401') WHEN a.SEASON=3 THEN CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0701') ELSE CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'1001') as TQBDT
    ,/* TQEDT= */ CASE WHEN a.SEASON = 1 THEN CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0301') WHEN a.SEASON=2 THENCONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0601') WHEN a.SEASON=3 THEN CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0901') ELSE CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'1201') as TQEDT
    ,/* TQDYS= */ CASE WHEN a.SEASON=1 THEN DATEDIFF(CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0101'),CONVERT(DATETIME,CAST(a.DATADT AS VARCHAR(4))+'0331'))WHEN a.SEASON=2 THEN 90 WHEN a.SEASON=3 THEN 91 ELSE 91 as TQDYS
    ,/* L1QBDT= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0101') WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0401') WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0701') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '1001') as L1QBDT
    ,/* L1QEDT= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0301') WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0601') WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0901') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '1201') as L1QEDT
    ,/* L1QDYS= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT))=1 THEN DATEDIFF(CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0101'),CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-1,a.DATADT),112) + '0331')WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT))=2 THEN 90 WHEN DATEPART(QUARTER,ADDDATE(QQ,-1,a.DATADT))=3 THEN 91 ELSE 91 END as L1QDYS
    ,/* L2QBDT= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-2,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-2,a.DATADT),112) + '0101') WHEN DATEPART(QUARTER,ADDDATE(QQ,-2,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-2,a.DATADT),112) + '0401') WHEN DATEPART(QUARTER,ADDDATE(QQ,-2,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-2,a.DATADT),112) + '0701') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-2,a.DATADT),112) + '1001') END as L2QBDT
    ,/* L2QEDT= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ-2,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '0301') WHEN DATEPART(QUARTER,ADDDATE(QQ-2,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '0601') WHEN DATEPART(QUARTER,ADDDATE(QQ-2,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '0901') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '1201') END as L2QEDT
    ,/* L2QDYS= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ-2,a.DATADT))=1 THEN DATEDIFF(CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '0101'),CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-2,a.DATADT),112) + '0331')WHEN DATEPART(QUARTER,ADDDATE(MM,-6,a.DATADT))=2 THEN 90 WHEN DATEPART(QUARTER,ADDDATE(MM,-6,a.DATADT))=3 THEN 91 ELSE 91 END as L2QDYS
    ,/* L3QBDT= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0101') WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0401') WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0701') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '1001') END as L3QBDT
    ,/* L3QEDT= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0301') WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0601') WHEN DATEPART(QUARTER,ADDDATE(QQ-3,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '0901') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ-3,a.DATADT),112) + '1201') END as L3QEDT
    ,/* L3QDYS= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-3,a.DATADT))=1 THEN DATEDIFF(CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-3,a.DATADT),112) + '0101'),CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-3,a.DATADT),112) + '0331')WHEN DATEPART(QUARTER,ADDDATE(QQ,-3,a.DATADT))=2 THEN 90 WHEN DATEPART(QUARTER,ADDDATE(QQ,-3a.DATADT))=3 THEN 91 ELSE 91 END as L3QDYS
    ,/* L4QBDT= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '0101') WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '0401') WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '0701') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '1001') END as L4QBDT
    ,/* L4QEDT= */ CASE WHEN DATEPART(QUARTER,ADDDATE(MM,-6,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(MM,-6,a.DATADT),112) + '0301') WHEN DATEPART(QUARTER,ADDDATE(MM,-6,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(MM,-6,a.DATADT),112) + '0601') WHEN DATEPART(QUARTER,ADDDATE(MM,-6,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(MM,-6,a.DATADT),112) + '0901') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(MM,-6,a.DATADT),112) + '1201') END as L4QEDT
    ,/* L4QDYS= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT))=1 THEN DATEDIFF(CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '0101'),CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-4,a.DATADT),112) + '0331')WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT))=2 THEN 90 WHEN DATEPART(QUARTER,ADDDATE(QQ,-4,a.DATADT))=3 THEN 91 ELSE 91 END as L4QDYS
    ,/* L5QBDT= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0101') WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0401') WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0701') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '1001') END as L5QBDT
    ,/* L5QEDT= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 1 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0301') WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 2 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0601') WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT)) = 3 THEN CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0901') ELSE CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '1201') END as L5QEDT
    ,/* L5QDYS= */ CASE WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT))=1 THEN DATEDIFF(CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0101'),CONVERT(DATETIME,CONVERT(VARHCAR(4),ADDDATE(QQ,-5,a.DATADT),112) + '0331')WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT))=2 THEN 90 WHEN DATEPART(QUARTER,ADDDATE(QQ,-5,a.DATADT))=3 THEN 91 ELSE 91 END as L5QDYS
    ,/* LstSysDt= */ GETDATE() as LstSysDt
    FROM ME-LBOT.odsdba.TMP_UN_DEDATE AS src
    WHERE NOT EXISTS(
        SELECT * FROM CB_DT AS A
        WHERE A.DATADT = CONVERT(DATETIME, CAST(TBSYY AS VARCHAR) + RIGHT('00' + CAST(TBSMM AS VARCHAR), 2) + RIGHT('00' + CAST(TBSDD AS VARCHAR), 2))
    )
;

SELECT @ERR_NO = @@ERROR, @INS_CNT = @@ROWCOUNT;
IF @ERR_NO<>0 GOTO BATCH_ERR_HANDLE;



-- Update 有用到Target Table的欄位---------------------
-- No such fields




------------------------------
-- 整批模式處理成功
------------------------------
PRINT 'Batch Mode : Finished Successfully';
PRINT '';
IF @RUN_MODE <> 'TEST' BEGIN
    COMMIT TRAN;
END;
GOTO WRITE_LOG;



-------------------------------------------------------------------------------
-- 整批模式錯誤處理
   BATCH_ERR_HANDLE:
-------------------------------------------------------------------------------
PRINT 'Batch Mode : Failure';
PRINT '';
IF @RUN_MODE <> 'TEST' BEGIN
    ROLLBACK TRAN;
END;










               
------------------------------
-- 執行結果紀錄
   WRITE_LOG:
------------------------------
IF @F_UPD_XSTATUS = 'T' BEGIN

    -- 計算 @DIFF_CNT
    IF @F_UPD_SRC_CNT='Y' BEGIN
        SELECT @DIFF_CNT = @SRC_CNT -(@INS_CNT + @UPD_CNT + @FLT_CNT);
    END ELSE BEGIN
        SELECT @DIFF_CNT = @BATCH_CNT -(@INS_CNT + @UPD_CNT + @FLT_CNT);
    END;

    -- 更新 XSTATUS
    EXEC [dbo].[sp_XStatusFinish] @BATCH_NO, @JOB_STAGE, @JOB_FLOW, @JOB_SEQ, @JOB_START_TIME,   @INS_CNT, @UPD_CNT, @DIFF_CNT, @LOOKUP_IND, @ERR_NO;

END;

print '@SRC_CNT     =' + STR(@SRC_CNT);
print '@SRC_SEL_CNT =' + STR(@SRC_SEL_CNT);
print '@INS_CNT     =' + STR(@INS_CNT);
print '@UPD_CNT     =' + STR(@UPD_CNT);
print '@INS+@UPD    =' + STR(@INS_CNT + @UPD_CNT);

------------------------------
-- 程式結束 sp_CB_DT_TMP_UN_DEDATE
------------------------------
IF @ERR_NO<>0 RAISERROR(@ERR_NO, 16, 1);
RETURN(@ERR_NO)
GO


