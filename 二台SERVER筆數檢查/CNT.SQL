       SELECT S1.NAME AS TABLENAME,S1.ROWS AS DW_CNT,S2.ROWS AS DP_CNT
       FROM ##MD_TABLEUsage S1
           ,[SDW00ETD21].TEMPDB.ODSDBA.##MD_TABLEUsage S2
       WHERE S1.NAME = S2.NAME
         AND S1.ROWS <> S2.ROWS  