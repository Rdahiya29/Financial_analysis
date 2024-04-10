/*
Financial Statement Analysis | Profit and Loss Statement Preparation | Balance Sheet Preparation | Cash Flow Statement Preparation |Report Creation 

Skills used: Joins, CTE's, Windows Functions, Aggregate Functions, CASE, Converting Data Types , Views , Subquery,Pivot,Union

--==> This means insights/inferences
*/

--Let's explore the dataset 

--What all tables are used in analysis

--==> COA, GL , Calendar , Territory, CF

--Get the range of dates for the GL 

Select min(Date) , max(Date) 
from GL

--==> Data is from January 2018 to September 2020 


--Countries that Buisness Captures 

Select * from Territory

--==> USA,Canada,UK,Germany,France,Australia,New Zealand


--Preparing Profit and Loss Statement for the whole company

Select Report,Class,Account,Format([2018],'N0') as '2018',Format([2019],'N0') as '2019',Format([2020],'N0') as '2020' from
(Select GL.Account_key,Report,Class,Account,YEAR(Date) as Year,SUM(Amount) as Amount
from GL Join COA
ON GL.Account_key = COA.Account_key
where Report = 'Profit and Loss'
Group by GL.Account_key,Report,Class,Account,YEAR(Date)) as T1
Pivot
(SUM(Amount) 
 For Year IN ([2018],[2019],[2020]))as T2
 Order by Account_key

 --Preparing Profit and Loss Statement for Canada

Select Country,Report,Class,Account,Format([2018],'N0') as '2018',Format([2019],'N0') as '2019',Format([2020],'N0') as '2020' from
(
Select Country,GL.Account_key,Report,Class,Account,YEAR(Date) as Year,SUM(Amount) as Amount
from GL Join COA
ON GL.Account_key = COA.Account_key
join Territory ON GL.Territory_key = Territory.Territory_Key
where Report = 'Profit and Loss' and Country ='Canada'  -- Similarly you can create PandL statement forany countries
Group by Country,GL.Account_key,Report,Class,Account,YEAR(Date)) as T1
Pivot
(Sum(Amount)
 For Year IN ([2018],[2019],[2020]))as T2


----Preparing Balance Sheet

Select Report,Class,SubClass,SubClass2,Account,SubAccount,Format([2018],'N0') as '2018',Format([2019],'N0')'2019',Format([2020],'N0')'2020'
from
(Select Distinct YEAR(Date) as Year,Country,Report,Class,SubClass,SubClass2,Account,SubAccount,
SUM(Amount) Over(Partition by SubAccount order by YEAR(Date))as Amount 
from GL Join COA ON GL.Account_key = COA.Account_key
Join Territory ON GL.Territory_key = Territory.Territory_key
where Report = 'Balance Sheet') as T1
Pivot
(Sum(Amount) For Year IN ([2018],[2019],[2020])) as T2


-- Profit and Loss Values calculation for ratio calculation and Putting all values in VIEW
--1.Sales
--2.Gross_Profit
--3.EBITDA
--4.Operating_Profit
--5.PBIT
--6.Net_Profit

Create View P_and_LValues as

Select Country,YEAR(Date) as Year,
SUM(Case when SubClass = 'Sales' then Amount else 0 end ) as 'Sales',
SUM(Case when Class = 'Trading Account' then Amount else 0 end ) as 'Gross_Profit',
SUM(Case when SubClass IN ('Sales','Cost of Sales','Operating Expenses') then Amount else 0 end ) as 'EBITDA',
SUM(Case when Class IN ('Trading account','Operating account') then Amount else 0 end ) as 'Operating_Profit' ,
SUM(Case when Class IN ('Trading account','Operating account','Non-Operating ') then Amount else 0 end ) as 'PBIT'  ,
SUM(Case when Report = 'Profit and Loss' then Amount else 0 end ) as 'Net_Profit',
SUM(Case when SubClass = 'Cost of Sales' then Amount else 0 end ) as 'Cost_of_Sales',
SUM(Case when SubClass = 'Interest Expense' then Amount else 0 end ) as 'Interest_Expense'
from GL join COA 
ON GL.Account_key=COA.Account_key
Join Territory ON 
GL.Territory_key = Territory.Territory_key
group by Country,YEAR(Date);


--Caluculating Balance Sheet Values for ratio calculation and Putting all values in VIEW

Create View BS_Values as
Select Distinct Country, YEAR(Date) as 'Year',
SUM(Case when Class = 'Assets' Then amount else 0 end) Over(Partition by Country Order by Year(Date)) as 'Assets',
SUM(Case when SubClass2 = 'Current Assets' Then amount else 0 end) Over(Partition by Country Order by Year(Date)) as 'Current Assets',
SUM(Case when SubClass2 = 'Non-Current Assets' Then amount else 0 end) Over(Partition by Country Order by Year(Date)) as 'Non-Current Assets',
SUM(Case when SubClass = 'Liabilities' Then amount else 0 end) Over(Partition by Country Order by Year(Date)) as 'Liabilities',
SUM(Case when SubClass2 = 'Current Liabilities' Then amount else 0 end) Over(Partition by Country Order by Year(Date)) as 'Current Liabilities',
SUM(Case when SubClass2 = 'Long Term Liabilities' Then amount else 0 end) Over(Partition by Country Order by Year(Date)) as 'NonCurrent_Liabilities',
SUM(Case when SubClass = 'Owners Equity' Then amount else 0 end) Over(Partition by Country Order by Year(Date)) as 'Equity',
SUM(Case when Class = 'Liabilities and Owners Equity' Then amount else 0 end) Over(Partition by Country Order by Year(Date)) as 'Liabilities and Equity',
SUM(Case when Account = 'Inventory' Then amount else 0 end) Over(Partition by Country Order by Year(Date)) as 'Inventory',
SUM(Case When SubAccount = 'Trade Receivables' then Amount else 0 end) Over ( Partition by Country Order by  Year(Date)) as 'Trade_Receivables',
SUM(Case When SubAccount = 'Trade Payables' then Amount else 0 end) Over ( Partition by Country Order by  Year(Date)) as 'Trade_Payables'
From COA join GL ON COA.account_key = GL.account_key
Join Territory ON GL.Territory_key = Territory.Territory_key



--Compiling all key Values in one View

Create View Fin_Values as
Select BS.* , PL.Sales,PL.Gross_Profit,PL.Net_Profit,PL.Operating_Profit,PL.PBIT,PL.EBITDA,PL.Cost_of_Sales,PL.Interest_Expense
from BS_Values BS Join P_and_LValues PL 
ON BS.Country = PL.Country and BS.Year = PL.Year



--Calculating  Profit and Loss and Balance Sheet ratios

Select YEAR,
Round(SUM(Gross_Profit) / SUM(Sales) * 100,2) as 'GP_Margin',
Round(SUM(Operating_Profit) / SUM(Sales) * 100 ,2)as 'Operating_Margin',
Round(SUM(Net_Profit)/ SUM(Sales) *100,2) as 'Net_Profit_Margin',
Round(SUM(Sales)/ SUM(Assets) *100,2) as 'Asset_Turnover',
Round(SUM(PBIT)/ SUM(Equity+NonCurrent_Liabilities) *100,2) as 'ROCE',
Round(SUM(Net_Profit)/ SUM(Equity) *100,2) as 'ROE',
Round(SUM(Liabilities)/ SUM(Equity) *100,2) as 'Gearing',
Round(SUM([Current Assets])/ SUM([Current Liabilities]),2) as 'Current_Ratio',
Round((Sum([Current Assets])-SUM(Inventory))/Sum([Current Liabilities]),2)  as 'Quick_Ratio',
Round(SUM(PBIT)/ SUM(Interest_expense)* -1,2) as 'Interest_Cover',
Round(SUM(Inventory)/ SUM(Cost_of_Sales)* -365,0) as 'Inventory_turnover_period',
Round(SUM(Trade_Receivables)/ SUM(Sales)* 365,0) as 'Receivables_turnover_period',
Round(SUM(Trade_Payables)/ SUM(Cost_of_Sales)* -365,0) as 'Payables_turnover_period'
from Fin_Values
group by Year;


--Preparing Cash Flow Statement


Select RANK ,Type, Subtype, [2018] , [2019], [2020]
from(
Select Rank, Type, Subtype, Year(Date) as Year,
SUM( Case when ValueType = 'All_FTP' Then Amount 
          when ValueType = 'All_FTP_CS' Then Amount * -1
		  when ValueType = 'All_FTP_Negative' and Amount < 0 Then Amount 
		  when ValueType = 'All_FTP_Positive' and Amount > 0 Then Amount 
		  when ValueType = 'All_FTP_Negative_CS' and Amount < 0 Then Amount * -1
		  when ValueType = 'All_FTP_Positive_CS' and Amount > 0 Then Amount  * -1
else 0 end) as Amount
from CF join GL ON CF.Account_key = GL. Account_key
where ValueType NOT IN ('Opening_balance' , 'Closing_balance')
group by Rank, Type, Subtype, Year(Date)) as T1
Pivot
(Sum(amount) for Year IN ([2018],[2019],[2020])) as T2

--Calculating Cash and Cash Equivalents at the end of the year 

Select Rank,TYPE,Subtype,[2018],[2019],[2020]
from(
Select Distinct Rank,TYPE,Subtype,YEAR(Date) as 'Year',
SUM(amount) Over(Partition by Rank,Type,Subtype Order by Year(Date)) as Amount
from CF Join GL ON CF.Account_key = GL.Account_key
Where TYPE = 'Cash and Cash equivalents at the end of the year') as T1
Pivot(
Sum(Amount) For Year IN ([2018],[2019],[2020])) as T2


--Calculating Cash and Cash Equivalents at the Start of the year 

Select Rank,Type,Subtype,[2018],[2019],[2020]
from
(
Select Rank = 1, TYPE = 'Cash and Cash equivalents at the start of the year', Subtype,Year,
LAG(Amount,1,0) Over (Order by Year) as Amount
From(
Select Distinct Rank,TYPE,Subtype,YEAR(Date) as Year,
SUM(amount) Over(Partition by Rank,Type,Subtype Order by Year(Date)) as Amount
from CF Join GL ON CF.Account_key = GL.Account_key
Where TYPE = 'Cash and Cash equivalents at the end of the year')as T1
)T2
Pivot
(Sum(amount) 
 For Year IN ([2018],[2019],[2020])) as T3;


 --Compiling Cash Flow Statement

 Select Rank,Type,Subtype,[2018],[2019],[2020]
from
(
Select Rank = 1, TYPE = 'Cash and Cash equivalents at the start of the year', Subtype,Year,
LAG(Amount,1,0) Over (Order by Year) as Amount
From(
Select Distinct Rank,TYPE,Subtype,YEAR(Date) as Year,
SUM(amount) Over(Partition by Rank,Type,Subtype Order by Year(Date)) as Amount
from CF Join GL ON CF.Account_key = GL.Account_key
Where TYPE = 'Cash and Cash equivalents at the end of the year')as T1
)T2
Pivot
(Sum(amount) 
 For Year IN ([2018],[2019],[2020])) as T3

Union

Select RANK ,Type, Subtype, [2018] , [2019], [2020]
from(
Select Rank, Type, Subtype, Year(Date) as Year,
SUM( Case when ValueType = 'All_FTP' Then Amount 
          when ValueType = 'All_FTP_CS' Then Amount * -1
		  when ValueType = 'All_FTP_Negative' and Amount < 0 Then Amount 
		  when ValueType = 'All_FTP_Positive' and Amount > 0 Then Amount 
		  when ValueType = 'All_FTP_Negative_CS' and Amount < 0 Then Amount * -1
		  when ValueType = 'All_FTP_Positive_CS' and Amount > 0 Then Amount  * -1
else 0 end) as Amount
from CF join GL ON CF.Account_key = GL. Account_key
where ValueType NOT IN ('Opening_balance' , 'Closing_balance')
group by Rank, Type, Subtype, Year(Date)) as T1
Pivot
(Sum(amount) for Year IN ([2018],[2019],[2020])) as T2

Union
Select Rank,TYPE,Subtype,[2018],[2019],[2020]
from(
Select Distinct Rank,TYPE,Subtype,YEAR(Date) as 'Year',
SUM(amount) Over(Partition by Rank,Type,Subtype Order by Year(Date)) as Amount
from CF Join GL ON CF.Account_key = GL.Account_key
Where TYPE = 'Cash and Cash equivalents at the end of the year') as T1
Pivot(
Sum(Amount) For Year IN ([2018],[2019],[2020])) as T2