SET ROWCOUNT 1

WHILE 1=1
BEGIN

/*UPDATE dbo.TBL
SET col1 = 4
WHERE col1 = 2
*/

INSERT INTO DBO.T2 (A,B)
SELECT S1.A,S1.B
FROM DBO.T1 S1 LEFT OUTER JOIN DBO.T2 S2 ON (S2.A = S1.A AND S2.B = S1.B)
WHERE S2.A IS NULL

IF @@ROWCOUNT = 0 BREAK
END


