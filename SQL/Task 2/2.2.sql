-- 2.2 Enrich 2.1 query with the cumulative_sum of the total amount with tax earned per country & region.

WITH sales AS (
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
                        Region)
    
    SELECT
        order_month,
        CountryRegionCode,
        Region,
        number_orders,
        number_customers,
        no_SalesPersons,
        Total_w_tax, 
        SUM(Total_w_tax) OVER (PARTITION BY CountryRegionCode, Region ORDER BY order_month) AS cumulative_sum
    FROM sales
    ORDER BY CountryRegionCode, Region;
