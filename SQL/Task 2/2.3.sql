-- 2.3 Enrich 2.2 query by adding ‘sales_rank’ column that ranks rows from best to worst for each country based on total amount with tax earned each month.
-- I.e. the month where the (US, Southwest) region made the highest total amount with tax earned will be ranked 1 for that region and vice versa.

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
        RANK() OVER (PARTITION BY CountryRegionCode, Region 
              ORDER BY Total_w_tax DESC) AS country_sales_rank,
        SUM(Total_w_tax) OVER (PARTITION BY CountryRegionCode, Region 
              ORDER BY order_month) AS cumulative_sum
    FROM sales
    WHERE Region = 'France'
    ORDER BY CountryRegionCode, Region, country_sales_rank;
