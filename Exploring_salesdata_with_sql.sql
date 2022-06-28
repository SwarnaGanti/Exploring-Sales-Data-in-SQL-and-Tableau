-- Inspecting Data
SELECT * FROM [Portfolio_DB].[dbo].[sales_data_sample]
-- Checking Unique values
SELECT DISTINCT STATUS FROM [Portfolio_DB].[dbo].[sales_data_sample] -- to plot in Tableau
SELECT DISTINCT YEAR_ID FROM [Portfolio_DB].[dbo].[sales_data_sample]
SELECT DISTINCT PRODUCTLINE FROM [Portfolio_DB].[dbo].[sales_data_sample] -- to plot
SELECT DISTINCT COUNTRY FROM [Portfolio_DB].[dbo].[sales_data_sample] -- to plot
SELECT DISTINCT DEALSIZE FROM [Portfolio_DB].[dbo].[sales_data_sample] -- to plot
SELECT DISTINCT TERRITORY FROM [Portfolio_DB].[dbo].[sales_data_sample] -- to plot
-- Analysis
SELECT PRODUCTLINE, SUM(SALES) AS REVENUE FROM [Portfolio_DB].[dbo].[sales_data_sample]
GROUP BY PRODUCTLINE
ORDER BY REVENUE DESC 
-- Classic cars is the best product line, followed by vintage cars
SELECT YEAR_ID, SUM(SALES) AS REVENUE FROM [Portfolio_DB].[dbo].[sales_data_sample]
GROUP BY YEAR_ID
ORDER BY REVENUE DESC 
-- Year 2004 made most sales
--Year 2005 seems to have less sales, further analysing data for year 2005
SELECT DISTINCT MONTH_ID FROM [Portfolio_DB].[dbo].[sales_data_sample]
WHERE YEAR_ID = 2005
-- They operated for only 5 months in year 2005

SELECT DEALSIZE, SUM(SALES) AS REVENUE FROM [Portfolio_DB].[dbo].[sales_data_sample]
GROUP BY DEALSIZE
ORDER BY REVENUE DESC 
-- Medium Dealsize generate the maximum revenue

-- What was the best month for sales in a specific year? How much was earned that month?
SELECT MONTH_ID, ROUND(SUM(SALES),2) AS REVENUE, COUNT(ORDERNUMBER) AS Num_of_ORDERS FROM [Portfolio_DB].[dbo].[sales_data_sample]
WHERE YEAR_ID = 2004 -- change the year
GROUP BY MONTH_ID
ORDER BY REVENUE DESC 
-- For year 2003 & 2004 , Month of November is the month with most number of orders and maximum revenue
-- What product do they sell the most in the month of November, Classic Cars??
SELECT MONTH_ID,PRODUCTLINE, ROUND(SUM(SALES),2) AS REVENUE, COUNT(ORDERNUMBER) AS Num_of_ORDERS FROM [Portfolio_DB].[dbo].[sales_data_sample]
WHERE YEAR_ID = 2003 and MONTH_ID = 11 
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY REVENUE DESC 
-- As guessed, best productline is Classic Cars in the month of November

--Who is our best customer? Using RFM Analysis (Recency - last order, Frequency - count of total orders, Monetary value - Total spend)

DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	SELECT 
		CUSTOMERNAME,
		SUM(SALES) AS MONETARYVALUE,
		AVG(SALES) AS AVGMONETARYVALUE,
		COUNT(ORDERNUMBER) AS FREQUENCY,
		MAX(ORDERDATE) AS last_order_date,
		(SELECT MAX(ORDERDATE) FROM [Portfolio_DB].[dbo].[sales_data_sample]) AS MAX_ORDER_DATE,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [Portfolio_DB].[dbo].[sales_data_sample])) AS RECENCY
	FROM [Portfolio_DB].[dbo].[sales_data_sample]
	GROUP BY CUSTOMERNAME
),
rfm_calc as 
(

	select r.*,
		NTILE(4) OVER (order by RECENCY DESC) rfm_recency,
		NTILE(4) OVER (order by FREQUENCY) rfm_frequency,
		NTILE(4) OVER (order by MONETARYVALUE) rfm_monetary
	FROM rfm r

)
select c.* , rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
cast( rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_calc c

SELECT CUSTOMERNAME, rfm_recency , rfm_frequency , rfm_monetary,
	CASE
		WHEN rfm_cell_string in (111, 112, 121, 122, 123, 131,132, 211, 212,213, 214,221, 113,114, 141, 142, 124) then 'lost customer' -- lost customers
		WHEN rfm_cell_string in (133, 134, 143, 144,243,234, 244) then 'slipping away, cannot lose' --(big spenders who haven't purchased lately, slipping away)
		WHEN rfm_cell_string in (311,312,313,314, 411,412,413,414,321, 421,422) then 'new customer'
		WHEN rfm_cell_string in (222, 223,224,231,241,232, 233,242, 323,322,324, 423,424) then 'potential customer'
		WHEN rfm_cell_string in (331,332,341,342,431,441,442, 432) then 'active' -- (customers who buy often & recently, but at low prices)
		WHEN rfm_cell_string in (333,334,343, 344,433, 434, 443, 444) then 'loyal'
	end rfm_segment
from #rfm
-- What products are most often bought together?

SELECT DISTINCT ORDERNUMBER, stuff(
	(SELECT ',' + PRODUCTCODE 
	FROM [Portfolio_DB].[dbo].[sales_data_sample] p
	WHERE ORDERNUMBER IN
	(
	SELECT ORDERNUMBER 
	FROM
	(
		SELECT ORDERNUMBER, COUNT(*) rn
		FROM [Portfolio_DB].[dbo].[sales_data_sample]p
		WHERE STATUS = 'Shipped'
		GROUP BY ORDERNUMBER
		)m
	WHERE rn = 2 -- change it to 3 
	)
	and p.ORDERNUMBER = s.ORDERNUMBER
	for xml path(''))
	,1,1,'') ProductCodes
FROM [Portfolio_DB].[dbo].[sales_data_sample] s
ORDER BY 2 DESC
---- (SS18_2325, S24_1937) , (S18_1342, S18_1367)were sold together 
-- S10_2016, S18_2625, S24_2000 were sold together


