--�H���p���覡�B�z
select s1.glorgno,s1.acctkey,s1.baltwd
from odsdba.FB_AcctLN2_DW s1
where datadt ='20050617' and baltwd 
 in (select top 50  baltwd from odsdba.FB_AcctLN2_DW s2
where datadt ='20050617' and s2.glorgno=s1.glorgno order by  s2.baltwd desc ) 
order by glorgno

--�Hcursor�B�z
--�ŧiCURSOR
DECLARE @SQL NVARCHAR(4000)
DECLARE @TableNm CHAR(3) --�ܼ�
DECLARE @TEMPCNT INT

SET @TEMPCNT = 0

create table #temp1 (acctkey [char](24),[GLORGNO] [char](3),[BALTWD] [numeric](14, 2) )

--TblList name
DECLARE TblList CURSOR FOR 

           SELECT  orgno
           from crmbasisdb.odsdba.cb_org
           where hdrdep =0;
           
   
        OPEN TblList; -- �}�l����
        FETCH NEXT FROM TblList --�Ĥ@��
             INTO @TableNm -- cursor�̪��ܼ�    
                                                                                                          
        WHILE @@FETCH_STATUS = 0   --�����ɴN����
     
BEGIN --�}�l�i��@�~
	
	insert into #temp1 (acctkey,GLORGNO,BALTWD)
	select top 50  acctkey,GLORGNO,BALTWD from odsdba.FB_AcctLN2_DW s2
where datadt ='20050617' and s2.glorgno=@TableNm
 order by  s2.baltwd desc 
   

       
   FETCH NEXT FROM TblList --�i��U�@��
   INTO @TableNm    
              SET @TEMPCNT = @TEMPCNT +1;
END   

CLOSE TblList;        --����cursor                                                                                                              
DEALLOCATE TblList;

select * from #temp1

--drop table #temp1



