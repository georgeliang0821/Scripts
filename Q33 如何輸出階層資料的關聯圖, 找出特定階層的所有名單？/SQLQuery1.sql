--�إߦۧڰѾ\�����u��ƪ�
if exists(select * from sys.tables where name='Employees')
drop table Employees
go
CREATE TABLE Employees
(
  empid     int  NOT NULL PRIMARY KEY ,   --���u�s��
  mgrid     int          	NULL,            --�D�޽s��
  empname varchar(25) 		NOT NULL,       --���u�m�W
  salary     money         NOT NULL,       --�~��
  CONSTRAINT FK_Employees_mgrid_empid
  FOREIGN KEY(mgrid)
  REFERENCES Employees(empid)  --�D�޽s���ݭn�s�b���u�s����
)
GO

--��J�C�@�ӭ��u���򥻸��
INSERT INTO Employees VALUES(1 , NULL, 'Nancy'   , $10000.00)
INSERT INTO Employees VALUES(2 , 1   , 'Andrew'  , $5000.00)
INSERT INTO Employees VALUES(3 , 1   , 'Janet'   , $5000.00)
INSERT INTO Employees VALUES(4 , 1   , 'Margaret', $5000.00) 
INSERT INTO Employees VALUES(5 , 2   , 'Steven'  , $2500.00)
INSERT INTO Employees VALUES(6 , 2   , 'Michael' , $2500.00)
INSERT INTO Employees VALUES(7 , 3   , 'Robert'  , $2500.00)
INSERT INTO Employees VALUES(8 , 3   , 'Laura'   , $2500.00)
INSERT INTO Employees VALUES(9 , 3   , 'Ann'     , $2500.00)
INSERT INTO Employees VALUES(10, 4   , 'Ina'     , $2500.00)
INSERT INTO Employees VALUES(11, 7   , 'David'   , $2000.00)
INSERT INTO Employees VALUES(12, 7   , 'Ron'     , $2000.00)
INSERT INTO Employees VALUES(13, 7   , 'Dan'     , $2000.00)
INSERT INTO Employees VALUES(14, 11  , 'James'   , $1500.00)
GO



;WITH EmpCTE(empid, empname, mgrid, lvl,sort,Salary)
AS
( 
-- ���I����
SELECT empid, empname, mgrid, 0,
cast(empid as varbinary(max)),Salary
  FROM Employees
  WHERE empid = 1      --��l���u�s��
UNION ALL  --�NCTE�����I�����P���j�����X�ֿ�X
-- ���j����
SELECT E.empid, E.empname, E.mgrid, M.lvl+1,
Sort+cast(e.empid as varbinary(max)),e.Salary
  FROM Employees AS E
    JOIN EmpCTE AS M   --�X��CTE����i��JOIN�d��
      ON E.mgrid = M.empid
)
SELECT REPLICATE('_',lvl*2)+empname+
'('+convert(varchar(30),empid)+')' '���u���h',
mgrid '�D�޽s��',lvl '���h'
FROM   EmpCTE
Order by sort
GO

-------------
;WITH EmpCTE(empid, empname, mgrid, lvl,sort,Salary)
AS
( 
  --���I����
  SELECT empid, empname, mgrid, 0,
cast(empid as varbinary(max)),Salary
  FROM Employees
  WHERE empid = 14 --�_�l�l�`�I
  UNION ALL  
  --���j����
  SELECT m.empid, m.empname, m.mgrid, e.lvl+1,
sort+cast(m.empid as varbinary(max)),m.Salary
  FROM  Employees AS m
    JOIN EmpCTE AS e
      ON m.empid = e.mgrid --�`�NJoin�覡
)
SELECT 
REPLICATE('_',((select max(lvl) from EmpCTE)-lvl)*2)+
empname+'('+convert(varchar(30),empid)+')' 
'���u���h',mgrid  '�D�޽s��',lvl '���h'
FROM EmpCTE
Order by sort desc
GO
