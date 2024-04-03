--SQL Advance Case Study
create database MobileManufacturer
use mobilemanufacturer
-- List all the states in which we have customers who have bought cellphones 
--from 2005 till today. 

--Q1--BEGIN -----------------------------------------------------------------------------------------------
	
select [state],count(idcustomer) Cust_Count, [Year]
from dim_location A
join fact_transactions B
on A.idlocation=B.idlocation
left join dim_date C 
on B.[date]=C.[date]
where [year]>=2005
group by [state],[year]

--Q1--END------------------------------------------------------------------------------------------

--Q2--BEGIN . What state in the US is buying the most 'Samsung' cell phones?

select top 1 [state],count(idcustomer) as Cust_COunt,Country,Manufacturer_Name
        from dim_location as A
        join fact_transactions as B
        on A.idlocation=B.idlocation
        left join dim_model as M
        on B.idmodel=M.idmodel
        left join dim_manufacturer as X
        on M.idmanufacturer=X.idmanufacturer
        where Country in ('us') and manufacturer_name = 'samsung'
        group by [state],Country,Manufacturer_Name
        order by Cust_COunt desc

--Q2--END

--Q3--BEGIN  Show the number of transactions for each model per zip code per state.    

select [state],idmodel,count(T.idmodel) as No_of_Transactions,ZipCode
from fact_transactions as T
   left join dim_location as L
   on T.idlocation=L.idlocation
group by ZipCode,[State],idmodel 

--Q3--END----------------------------------------------------

--Q4--BEGIN .Show the cheapest cellphone (Output should contain the price also)
	
	select top 1 Model_Name,Unit_Price as Cheapest_Cellphone
    from dim_model
    order by unit_price 

--Q4--END

--Q5--BEGIN  {Find out the average price for each model in the top5 manufacturers in 
--    terms of sales quantity and order by average price}
select Model_Name, avg(Totalprice) as Avg_Price
from 
    (
       select top 5 Manufacturer_Name , Model_Name,sum (quantity) as TotalQuantity,TotalPrice
       from fact_transactions as T
       left join dim_model as M
       on T.idmodel=M.idmodel
       left join dim_manufacturer as X
       on M.idmanufacturer=X.idmanufacturer
       group by quantity, model_name,manufacturer_name,TotalPrice
       order by sum(quantity) desc 
	  ) as Y
group by Model_Name
order by Avg_Price 
--END-------------------------------------------------------------------------------------------------------

--Q6List the names of the customers and the average amount spent in 2009,where the average is higher than 500
--BEGIN------------------
SELECT CUSTOMER_NAME,AVG(TOTALPRICE) AS TOT_AMOUNT,[YEAR]
fROM DIM_CUSTOMER A
LEFT JOIN FACT_TRANSACTIONS B
ON A.IDCustomer=B.IDCustomer
left join dim_date C
on B.[DATE]=C.[DATE]
WHERE [YEAR]=2009
GROUP BY CUSTOMER_NAME,[YEAR]
HAVING AVG(TOTALPRICE)>500
--END------------------------------------------------------------------------------------------------------


--Q7 List if there is any model that was in the top 5 in terms of quantity,simultaneously in 2008, 2009 and 2010.
--BEGIN--
SELECT*FROM
(SELECT TOP 5 MODEL_NAME,SUM(QUANTITY)AS TOT_QUANTITY,[YEAR]
FROM DIM_MODEL A
 JOIN FACT_TRANSACTIONS B
ON A.IDMODEL=B.IDMODEL
JOIN DIM_DATE C
ON B.[DATE]=C.[DATE]
WHERE [YEAR] =2008
GROUP BY MODEL_NAME,[YEAR]
ORDER BY SUM(QUANTITY) DESC) AS X

intersect
SELECT*FROM
(SELECT TOP 5 MODEL_NAME,SUM(QUANTITY)AS TOT_QUANTITY,[YEAR]
FROM DIM_MODEL A
 JOIN FACT_TRANSACTIONS B
ON A.IDMODEL=B.IDMODEL
JOIN DIM_DATE C
ON B.[DATE]=C.[DATE]
WHERE [YEAR] =2009
GROUP BY MODEL_NAME,[YEAR]
ORDER BY SUM(QUANTITY) DESC) AS Y
intersect
SELECT*FROM
(SELECT TOP 5 MODEL_NAME,SUM(QUANTITY)AS TOT_QUANTITY,[YEAR]
FROM DIM_MODEL A
 JOIN FACT_TRANSACTIONS B
ON A.IDMODEL=B.IDMODEL
JOIN DIM_DATE C
ON B.[DATE]=C.[DATE]
WHERE [YEAR] =2010
GROUP BY MODEL_NAME,[YEAR]
ORDER BY SUM(QUANTITY) DESC) AS Z
--END-----

--Q8 . Show the manufacturer with the 2nd top sales in the year of 2009 and the 
--manufacturer with the 2nd top sales in the year of 2010. 

--BEGIN----
SELECT*FROM
(SELECT*, RANK()OVER(ORDER BY TOT_AMOUNT DESC) AS RANK_NO FROM
(SELECT MANUFACTURER_NAME,SUM(TOTALPRICE)AS TOT_AMOUNT,[YEAR]
FROM DIM_MANUFACTURER W
LEFT JOIN DIM_MODEL X
ON W.IDManufacturer=X.IDManufacturer
LEFT JOIN FACT_TRANSACTIONS Y
ON X.IDModel=Y.IDModel
LEFT JOIN DIM_DATE Z
ON Y.[DATE]=Z.[DATE]
WHERE [YEAR]=2009
GROUP BY MANUFACTURER_NAME,[YEAR])AS A) AS C
WHERE RANK_NO=2

UNION ALL

SELECT*FROM
(SELECT*,RANK()OVER(ORDER BY TOT_AMOUNT DESC) AS RANK_NO FROM
(SELECT  MANUFACTURER_NAME,SUM(TOTALPRICE)AS TOT_AMOUNT,[YEAR]
FROM DIM_MANUFACTURER W
LEFT JOIN DIM_MODEL X
ON W.IDManufacturer=X.IDManufacturer
LEFT JOIN FACT_TRANSACTIONS Y
ON X.IDModel=Y.IDModel
LEFT JOIN DIM_DATE Z
ON Y.[DATE]=Z.[DATE]
WHERE [YEAR]=2010
GROUP BY MANUFACTURER_NAME,[YEAR]) AS B) AS D
WHERE RANK_NO=2
---END--------------------------------------------------------------------------------------------------------

--Q.9 Show the manufacturers that sold cellphones in 2010 but did not in 2009. 
--BEGIN-------------------------------------------------------------------------------
select Manufacturer_Name from FACT_TRANSACTIONS T
	left join DIM_MODEL as MO on T.IDModel = MO.IDModel
	left join DIM_MANUFACTURER as M on MO.IDManufacturer = M.IDManufacturer
	left join DIM_DATE D on D.[DATE]= T.[Date]
	where [YEAR] = 2010
	group by Manufacturer_Name
	except
	select Manufacturer_Name from FACT_TRANSACTIONS T
	left join DIM_MODEL as MO on T.IDModel = MO.IDModel
	left join DIM_MANUFACTURER as M on MO.IDManufacturer = M.IDManufacturer
	left join DIM_DATE D on D.[DATE]= T.[Date]
	where [YEAR] = 2009
	group by Manufacturer_Name
--END----------------------------------------------------------------------------
--Q10 Find top 10 customers and their average spend, average quantity by each year. Also find the percentage
--   of change in their spend. 
--BEGIN-----------------------
SELECT 
    T1.Customer_Name, T1.Year, T1.Avg_Price,T1.Avg_Qty,
    CASE
        WHEN T2.Year IS NOT NULL
        THEN FORMAT(CONVERT(DECIMAL(8,2),(T1.Avg_Price-T2.Avg_Price))/CONVERT(DECIMAL(8,2),T2.Avg_Price),'p') ELSE NULL 
        END AS 'YEARLY_%_CHANGE'
    FROM
        (SELECT t2.Customer_Name, YEAR(t1.DATE) AS YEAR, AVG(t1.TotalPrice) AS Avg_Price, AVG(t1.Quantity) AS Avg_Qty FROM FACT_TRANSACTIONS AS t1 
        left join DIM_CUSTOMER as t2 ON t1.IDCustomer=t2.IDCustomer
        where t1.IDCustomer in (select top 10 IDCustomer from FACT_TRANSACTIONS group by IDCustomer order by SUM(TotalPrice) desc)
        group by t2.Customer_Name, YEAR(t1.Date)
        )T1
    left join
        (SELECT t2.Customer_Name, YEAR(t1.DATE) AS YEAR, AVG(t1.TotalPrice) AS Avg_Price, AVG(t1.Quantity) AS Avg_Qty FROM FACT_TRANSACTIONS AS t1 
        left join DIM_CUSTOMER as t2 ON t1.IDCustomer=t2.IDCustomer
        where t1.IDCustomer in (select top 10 IDCustomer from FACT_TRANSACTIONS group by IDCustomer order by SUM(TotalPrice) desc)
        group by t2.Customer_Name, YEAR(t1.Date)
        )T2
        on T1.Customer_Name=T2.Customer_Name and T2.YEAR=T1.YEAR-1 
--END-----------------------------------------------------------------------------------------------------

	