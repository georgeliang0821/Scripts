1.    �ϥ� OpenRowset

 

SELECT * FROM OpenRowset('MSDASQL', 

  'Driver={Microsoft Text Driver (*.txt; *.csv)};

  DefaultDir=D:\Temp;',

  'SELECT TOP 5 * FROM MyText.txt where region = ''Taipei''')

 

2.    �ϥ� Link Server

 

EXEC sp_addlinkedserver txtserver, 'Jet 4.0',

  'Microsoft.Jet.OLEDB.4.0', 'D:\Temp', NULL, 'Text'

 

SELECT * FROM txtserver...MyTest#txt WHERE region = 'Taipei'

 

 �z�i�H�N�����x�s�쥻���ϺШíק� D:\Temp ���|�A����W�z�y�k�A�ݬO�_�i�H���`�d�ߥX���
