

--�ŧiCURSOR
DECLARE @tablename CHAR(40) --�ܼ�
DECLARE @COLNAME CHAR(20)

--tablename name
DECLARE tablename CURSOR FOR 

--�d�ߪ��A
select 'odsdb.odsdba.'+tablename,colname from dbo.XSurStatus
where left(rtrim(tablename),5) = 'odsms' 
  and run_status = 'runok'
 union all
select 'crmbasisdb.odsdba.cb_pcust_ms','UNINO'
union all
select 'crmbasisdb.odsdba.cb_pcust_ms','CUSTKEY'



   
        OPEN tablename; -- �}�l����
        FETCH NEXT FROM tablename --�Ĥ@��
             INTO @tablename,@COLNAME -- cursor�̪��ܼ�    
                                                                                                          
        WHILE @@FETCH_STATUS = 0   --�����ɴN����
     
BEGIN --�}�l�i��@�~


  --�ŧiCURSOR
DECLARE @DATADT CHAR(8) --�ܼ�
declare @sql nvarchar(4000)

 --Step2:�T�{��TABLE�O�_��DTADT��Index
 
             
     

         	
           DECLARE DATADTList CURSOR FOR 
           
             SELECT CONVERT(CHAR(8),TMNBDT,112) AS DATADT             
             FROM ODSDB.ODSDBA.CB_DT S1
             WHERE S1.BEOM_FG = 'Y' --�u�D�����
               AND TMNBDT BETWEEN '20050301' AND '20070701' ; --����CRM��ư_��P�ثe�I���
               
               
   
        OPEN DATADTList; 
        FETCH NEXT FROM DATADTList 
             INTO @DATADT 
                                                                                                          
        WHILE @@FETCH_STATUS = 0   
     
BEGIN 

  set @sql ='update s1
             set s1.'+RTRIM(@COLNAME)+' = s2.custkey
             from '+rtrim(@tablename)+' s1
             ,surdb.dbo.cb_surcust s2
             where  CONVERT(CHAR(11),s2.SUR_custkey) = S1.'+RTRIM(@COLNAME)+'
               and s1.datadt='''+rtrim(@datadt)+''''
    print @sql
    exec (@sql)
             
    
       
   FETCH NEXT FROM DATADTList 
   INTO @DATADT    
END   

CLOSE DATADTList;                                                                                                             
DEALLOCATE DATADTList;

       
   FETCH NEXT FROM tablename --�i��U�@��
   INTO @tablename,@COLNAME    
END   

CLOSE tablename;        --����cursor                                                                                                              
DEALLOCATE tablename;
