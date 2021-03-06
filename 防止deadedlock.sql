USE [ISMD]
GO
/****** Object:  StoredProcedure [odsdba].[SP_INS_Xbatchflowh_Xbatchflow]    Script Date: 08/07/2007 19:29:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [odsdba].[SP_INS_Xbatchflowh_Xbatchflow]
     @StartMode CHAR(7)
    ,@DataCat   CHAR(10)
AS  
/* 20070807 新增死結處理，如偵測到死結，則重新執行程式 BY Bibby*/

DECLARE @retry INT;  -- 死結處理，預設最多遇到死結5次
SET @retry = 5;

IF @StartMode = 'NORMAL' BEGIN
      --將前次批次記錄移至歷史檔
  WHILE (@retry > 0)
    BEGIN
      BEGIN TRY  -- 偵測死結錯誤
		INSERT INTO odsdba.XBATCHFLOWH  --將舊的記錄刪除
		SELECT * FROM odsdba.XBATCHFLOW WITH (NOLOCK)
		WHERE DATACAT = @DataCat;		
		  
		DELETE FROM odsdba.XBATCHFLOW	
		WHERE DATACAT = @DataCat;

        SET @retry = -2
      END TRY
      BEGIN CATCH  -- 遇到死結則重新執行，等待1分鐘後，再重新執行
        IF (ERROR_NUMBER() = 1205) BEGIN 
            SET @retry = @retry - 1; 
            WAITFOR DELAY '00:01:00'; END
        ELSE BEGIN 
            SET @retry = -1; END 
      END CATCH
    END

    IF @retry=0 BEGIN RAISERROR('Dead Locked !!',16,1); END  --死結狀況超過五次視為異常現象，故需回傳此錯誤
    IF @retry=-1 -- 由於錯誤原因非死結，需重現錯誤狀況
      BEGIN 
		INSERT INTO odsdba.XBATCHFLOWH  --將舊的記錄刪除
		SELECT * FROM odsdba.XBATCHFLOW WITH (NOLOCK)
		WHERE DATACAT = @DataCat;		
		  
		DELETE FROM odsdba.XBATCHFLOW	
		WHERE DATACAT = @DataCat;
      END

END ELSE BEGIN
      --將前次中斷批次記錄移至歷史檔
	INSERT INTO odsdba.XBATCHFLOWH
	SELECT * FROM odsdba.XBATCHFLOW WITH (NOLOCK)
	WHERE DATACAT = @DataCat 
	  AND RUN_STATUS = 'ABORT';
END