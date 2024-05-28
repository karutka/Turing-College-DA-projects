/*
This query gets data used for Total Revenue and Profit-related KPIs.
The results of this query were imported to Power BI as 'Sales Product' Table.
*/

-- Choosing needed columns from different tables
SELECT
  salesorderheader.SalesOrderID AS SalesOrderID,
  salesorderheader.SubTotal AS SubTotal,
  salesorderheader.TotalDue AS TotalDue,
  salesorderdetail.OrderQty AS OrderQty,
  salesorderdetail.UnitPrice AS UnitPrice,
  product.ProductID AS ProductID,
  product.StandardCost AS StandardCost,
  product.ListPrice AS ListPrice
-- Combining rows from three tables, based on a related column between them
FROM
  `tc-da-1.adwentureworks_db.salesorderheader` AS salesorderheader
JOIN
  `tc-da-1.adwentureworks_db.salesorderdetail` AS salesorderdetail
ON
  salesorderheader.SalesOrderID = salesorderdetail.SalesOrderID
JOIN
  `tc-da-1.adwentureworks_db.product` AS product
ON
  salesorderdetail.ProductID = product.ProductID
