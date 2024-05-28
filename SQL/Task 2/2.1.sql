-- 2.1 Create a query of monthly sales numbers in each Country & region. Include in the query a number of orders, customers and
-- sales persons in each month with a total amount with tax earned. Sales numbers from all types of customers are required.

SELECT 
    LAST_DAY(CAST(salesorderheader.OrderDate AS date), month) AS order_month,
    salesteritorry.CountryRegionCode AS CountryRegionCode,
    salesteritorry.Name AS Region,
    COUNT(DISTINCT salesorderheader.SalesOrderID) AS number_orders,
    COUNT(DISTINCT salesorderheader.CustomerID) AS number_customers,
    COUNT(DISTINCT salesorderheader.SalesPersonID) AS no_SalesPersons,
    ROUND(SUM(salesorderheader.TotalDue)) AS Total_w_tax
FROM `adwentureworks_db.salesorderheader` AS salesorderheader
JOIN `adwentureworks_db.salesterritory` AS salesteritorry
ON salesorderheader.TerritoryID = salesteritorry.TerritoryID
GROUP BY order_month, 
		CountryRegionCode, 
		Region;
