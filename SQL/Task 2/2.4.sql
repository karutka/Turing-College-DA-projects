-- 2.4 Enrich 2.3 query by adding taxes on a country level:
-- As taxes can vary in country based on province, the needed column is ‘mean_tax_rate’ -> average tax rate in a country.
-- Also, as not all regions have data on taxes, you also want to be transparent and show the ‘perc_provinces_w_tax’ -> a column representing the percentage
-- of provinces with available tax rates for each country (i.e. If US has 53 provinces, and 10 of them have tax rates, then for US it should show 0,19)

WITH sales AS (
    SELECT 
        LAST_DAY(CAST(salesorderheader.OrderDate AS date), month) AS order_month,
        salesteritorry.CountryRegionCode AS CountryRegionCode,
        salesteritorry.Name AS Region,
        COUNT(DISTINCT salesorderheader.SalesOrderID) AS number_orders,
        COUNT(DISTINCT salesorderheader.CustomerID) AS number_customers,
        COUNT(DISTINCT salesorderheader.SalesPersonID) AS no_SalesPersons,
        CAST(ROUND(SUM(salesorderheader.TotalDue)) AS INT64) AS Total_w_tax
    FROM `adwentureworks_db.salesorderheader` AS salesorderheader
    JOIN `adwentureworks_db.salesterritory` AS salesteritorry
    ON salesorderheader.TerritoryID = salesteritorry.TerritoryID
    GROUP BY 1, 2, 3),

tax_rates AS (
    SELECT
        countryregion.CountryRegionCode AS CountryRegionCode,
        ROUND(AVG(salestaxrate.TaxRate), 1) AS mean_tax_rate,
        COUNT(stateprovince.StateProvinceID) AS total_provinces,
        COUNT(CASE WHEN salestaxrate.TaxRate IS NOT NULL 
            THEN stateprovince.StateProvinceID END) AS provinces_with_tax,
    FROM `adwentureworks_db.countryregion` AS countryregion
    JOIN `adwentureworks_db.stateprovince` AS stateprovince
    ON countryregion.CountryRegionCode = stateprovince.CountryRegionCode
    LEFT JOIN `adwentureworks_db.salestaxrate` AS salestaxrate
    ON stateprovince.StateProvinceID = salestaxrate.StateProvinceID
    GROUP BY 1
        )
    
    SELECT
        sales.order_month,
        sales.CountryRegionCode,
        sales.Region,
        sales.number_orders,
        sales.number_customers,
        sales.no_SalesPersons,
        sales.Total_w_tax, 
        RANK() OVER (PARTITION BY sales.CountryRegionCode, sales.Region 
            ORDER BY sales.Total_w_tax DESC) AS country_sales_rank,
        SUM(sales.Total_w_tax) OVER (PARTITION BY sales.CountryRegionCode, sales.Region 
            ORDER BY sales.order_month) AS cumulative_sum,
        tax_rates.mean_tax_rate,
        ROUND(tax_rates.provinces_with_tax / tax_rates.total_provinces, 2) AS perc_provinces_w_tax
    FROM sales
    JOIN tax_rates
    ON sales.CountryRegionCode = tax_rates.CountryRegionCode
        WHERE sales.CountryRegionCode = 'US' AND sales.Region = 'Southwest'
    ORDER BY country_sales_rank;
