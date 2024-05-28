/*
This query gets data used for a slicer that filters dashboard visuals 
according to the country. The results of this query were imported 
to Power BI as 'Sales Territory' Table.
*/

SELECT
  TerritoryID,
  Name,
  CountryRegionCode
FROM
  `tc-da-1.adwentureworks_db.salesterritory`
