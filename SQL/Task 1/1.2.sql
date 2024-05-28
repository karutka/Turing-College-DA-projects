-- 1.2 Business finds the original query valuable to analyze customers and now want to get the data from 
-- the first query for the top 200 customers with the highest total amount (with tax) who have not ordered
-- for the last 365 days. How would you identify this segment?

WITH customer_info AS (
        SELECT 
            individual.CustomerID AS CustomerId, 
            contact.Firstname AS FirstName,
            contact.LastName AS LastName,
            CONCAT(contact.Firstname, ' ', contact.LastName) AS full_name,
            CONCAT(IFNULL(contact.Title, 'Dear'), ' ', contact.LastName) AS addressing_title,
            contact.Emailaddress AS EmailAddress,
            contact.Phone AS Phone,
            customer.AccountNumber AS AccountNumber,
            customer.CustomerType AS CustomerType,
            address.City AS City,
            address.AddressLine1 AS AddressLine1,
            address.AddressLine2 AS AddressLine2,
            stateprovince.Name AS State,
            countryregion.Name AS Country
        FROM `adwentureworks_db.individual` AS individual
        JOIN `adwentureworks_db.contact` AS contact 
        ON individual.ContactID = contact.ContactId
        JOIN `adwentureworks_db.customer` AS customer 
        ON individual.CustomerID = customer.CustomerID
        JOIN (
            SELECT 
                CustomerID,
                MAX(AddressID) AS LatestAddressId
            FROM `adwentureworks_db.customeraddress`
            GROUP BY CustomerID
        ) AS latest_address 
        ON customer.CustomerID = latest_address.CustomerID
        JOIN `adwentureworks_db.address` AS address 
        ON latest_address.LatestAddressId = address.AddressID
        JOIN `adwentureworks_db.stateprovince` AS stateprovince 
        ON address.StateProvinceID = stateprovince.StateProvinceID
        JOIN `adwentureworks_db.countryregion` AS countryregion 
        ON stateprovince.CountryRegionCode = countryregion.CountryRegionCode
    ),
    sales_info AS (
        SELECT 
            CustomerID AS CustomerId,
            COUNT(SalesOrderId) AS number_orders,
            SUM(TotalDue) AS total_amount,
            MAX(OrderDate) AS date_last_order
        FROM `adwentureworks_db.salesorderheader` AS salesorderheader
        GROUP BY CustomerID
    ),
   info AS (
        SELECT 
            customer_info.CustomerId AS CustomerId,
            customer_info.FirstName AS FirstName,
            customer_info.LastName AS LastName,
            customer_info.full_name AS full_name,
            customer_info.addressing_title AS addressing_title,
            customer_info.EmailAddress AS EmailAddress,
            customer_info.Phone AS Phone,
            customer_info.AccountNumber AS AccountNumber,
            customer_info.CustomerType AS CustomerType,
            customer_info.City AS City,
            customer_info.AddressLine1 AS AddressLine1,
            customer_info.AddressLine2 AS AddressLine2,
            customer_info.State AS State,
            customer_info.Country AS Country,
            sales_info.number_orders AS number_orders,
            ROUND(sales_info.total_amount, 3) AS total_amount,
            sales_info.date_last_order AS date_last_order
        FROM customer_info
        JOIN sales_info 
        ON customer_info.CustomerId = sales_info.CustomerId
        ORDER BY sales_info.total_amount DESC
        )

SELECT *
FROM info
WHERE date_last_order < TIMESTAMP_SUB((SELECT MAX(OrderDate) 
    FROM `adwentureworks_db.salesorderheader`), INTERVAL 365 DAY)
LIMIT 200;
